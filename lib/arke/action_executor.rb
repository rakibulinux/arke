module Arke
  class ActionExecutor
    include Arke::Helpers::Precision
    attr_reader :id, :account, :logger

    def initialize(account, opts={})
      @account = account
      @id = account.id
      @logger = Arke::Log
      @purge_on_push = opts[:purge_on_push] ? true : false
      @queues = {}
      @timers = {}
    end

    def schedule_timers(queue_id, offset, period)
      EM::Synchrony.add_timer(offset) do
        @timers[queue_id] ||= EM::Synchrony.add_periodic_timer(period) do
          schedule(@queues[queue_id].shift) if @queues[queue_id]
        end
      end
    end

    def create_queue(queue_id)
      @queues[queue_id] = []
    end

    def start
      period = account.delay.to_d / @queues.size
      half_period = period / 2

      @queues.each_with_index do |(queue_id, _), idx|
        offset = half_period + period * idx
        if block_given?
          yield(queue_id, offset, period)
        else
          schedule_timers(queue_id, offset, period)
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

    private

    def execute
      Fiber.new { yield }.resume
    end

    def schedule(action)
      return unless action
      case action.type
      when :order_create
        execute do
          order = action.params[:order]
          logger.info { "ACCOUNT:#{id} Creating order: #{order}" }
          price = apply_precision(order.price, action.destination.quote_precision)
          amount = apply_precision(order.amount, action.destination.base_precision.to_f,
            order.side == :sell ? action.destination.min_ask_amount.to_f : action.destination.min_bid_amount.to_f)
          begin
            order = Arke::Order.new(order.market, price, amount, order.side)
            action.destination.account.create_order(order)
          rescue StandardError => e
            logger.error { "ACCOUNT:#{id} #{e}\n#{e.backtrace.join("\n")}" }
          end
        end
      when :order_stop
        execute do
          begin
            logger.info { "ACCOUNT:#{id} Canceling order: #{action.params}" }
            action.destination.account.stop_order(action.params[:order])
          rescue StandardError
            logger.error { "ACCOUNT:#{id} #{$!}" }
          end
        end
      when :fetch_openorders
        Arke::Log.info "ACCOUNT:#{id} Fetching open orders"
        action.destination.fetch_openorders
      when :noop
        Arke::Log.info "ACCOUNT:#{id} empty action"
      else
        logger.error { "ACCOUNT:#{id} Unknown Action type: #{action.type}" }
      end
    end
  end
end
