# frozen_string_literal: true

module Arke
  class ActionExecutor
    include ::Arke::Helpers::Precision
    attr_reader :id, :account, :logger

    def initialize(account, opts={})
      @account = account
      @id = account.id
      @logger = Arke::Log
      @purge_on_push = opts[:purge_on_push] ? true : false
      @queues = {}
      @delays = {}
      @timers = {}
      @enabled = true
    end

    def schedule_timers(queue_id, offset, periods)
      EM::Synchrony.add_timer(offset) do
        delays = (@delays[queue_id] || periods)
        logger.info "ACCOUNT:#{id} Scheduling timers for #{queue_id} with delays: #{delays}"
        delays.each_with_index do |period, i|
          @timers[queue_id] ||= []
          @timers[queue_id] << EM::Synchrony.add_periodic_timer(period) do
            if @queues[queue_id] && @enabled
              idx = ((@queues[queue_id].size / delays.size) * i).to_i
              action = @queues[queue_id].delete_at(idx)
              schedule(action)
            end
          end
        end
      end
    end

    def create_queue(queue_id, delays=nil)
      @queues[queue_id] = []
      @delays[queue_id] ||= delays
    end

    def start
      if @queues.empty?
        logger.info { "ACCOUNT:#{id} no strategy registered" }
        return
      end
      offset_period = account.delay.first / @queues.size

      @queues.each_with_index do |(queue_id, _), idx|
        offset = offset_period * idx
        if block_given?
          yield(queue_id, offset, account.delay)
        else
          schedule_timers(queue_id, offset, account.delay)
        end
      end
    end

    def push(queue_id, actions)
      if @purge_on_push
        @queues[queue_id] = actions
        return
      end
      @queues[queue_id] ||= []
      actions.each do |action|
        @queues[queue_id] << action
      end
    end

    def stop
      logger.debug { "ACCOUNT:#{id} Closed queue for #{account}" }
      @timers.each_value(&:cancel)
    end

    #
    # Disable the executor during the fetch of open orders
    # Let some time before the call to make sure pending orders are process by the platform
    #
    def fetch_openorders(destination, grace_time)
      return unless @enabled

      @enabled = false
      logger.info { "ACCOUNT:#{id} Fetching open orders, disabling executor for #{grace_time} secs" }
      Fiber.new do
        EM::Synchrony.sleep(grace_time)
        destination.fetch_openorders
        @enabled = true
      end.resume
    end

    private

    def execute
      Fiber.new { yield }.resume
    end

    def colored_side(side)
      return "buy".green if side.to_sym == :buy
      return "sell".red if side.to_sym == :sell

      side
    end

    CREATING = "Creating".green
    CANCELING = "Canceling".red

    def schedule(action)
      return unless action

      case action.type
      when :order_create
        execute do
          order = action.params[:order]
          order.apply_requirements(action.destination.account)
          logger.info { "ACCOUNT:#{id} #{CREATING} #{colored_side(order.side)} order: #{action.params}" }

          begin
            action.destination.account.create_order(order)
          rescue StandardError => e
            logger.error { "ACCOUNT:#{id} #{e}\n#{e.backtrace.join("\n")}" }
          end
        end

      when :order_stop
        execute do
          order = action.params[:order]
          logger.info { "ACCOUNT:#{id} #{CANCELING} #{colored_side(order.side)} order: #{action.params}" }
          action.destination.account.stop_order(order)
        rescue StandardError => e
          logger.error { "ACCOUNT:#{id} #{e}" }
        end

      when :fetch_openorders
        logger.info { "ACCOUNT:#{id} Fetching open orders" }
        action.destination.fetch_openorders

      when :noop
        logger.info { "ACCOUNT:#{id} noop" }

      else
        logger.error { "ACCOUNT:#{id} Unknown Action type: #{action.type}" }
      end
    end
  end
end
