module Arke
  class ActionExecutor
    include Arke::Helpers::Precision
    attr_reader :id, :account, :logger

    def initialize(account, opts={})
      @account = account
      @id = account.id
      @queue = EM::Queue.new
      @logger = Arke::Log
      @purge_on_push = opts[:purge_on_push] ? true : false
    end

    def start
      @timer ||= EM::Synchrony.add_periodic_timer(account.delay) do
        unless @queue.empty?
          @queue.pop do |action|
            schedule(action)
          end
        end
      end
    end

    def push(actions)
      @queue = EM::Queue.new if @purge_on_push
      actions.each do |action|
        @queue << action
      end
    end

    def stop
      @queue.close()
      logger.debug { "ACCOUNT:#{id} Closed queue for #{account}" }
      @timer.cancel()
    end

    private

    def execute
      Fiber.new { yield }.resume
    end

    def schedule(action)
      case action.type
      when :order_create
        execute do
          order = action.params[:order]
          logger.info { "ACCOUNT:#{id} Creating order: #{order}" }
          order = action.params[:order]
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
      else
        logger.error { "ACCOUNT:#{id} Unknown Action type: #{action.type}" }
      end
    end
  end
end
