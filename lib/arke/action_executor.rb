require "singleton"

module Arke
  class ActionExecutor
    include Arke::Helpers::Precision
    attr_accessor :exchanges
    attr_reader :id

    def initialize(config)
      @exchanges = {}
      @id = config["id"]
      Array(config["sources"]).each do |source|
        @exchanges[source["driver"].to_sym] = { delay: source["delay"].to_f }
      end
      @exchanges[config["target"]["driver"].to_sym] = { delay: config["target"]["delay"].to_f }
      create_queues
      self
    end

    def start
      @exchanges.each do |ex, config|
        config[:timer] = EM::Synchrony::add_periodic_timer(config[:delay]) do
          unless config[:queue].empty?
            config[:queue].pop do |action|
              schedule(action)
            end
          end
        end
      end
    end

    def push(actions)
      clear_queue(actions[0].destination.driver.to_sym) unless actions.empty?
      actions.each do |action|
        ex = action.destination.driver.to_sym
        @exchanges[ex][:queue] << action
      end
    end

    def stop
      @exchanges.each do |ex, config|
        config[:queue].close()
        Arke::Log.debug "ID:#{id} Closed queue for #{ex}"
        config[:timer].cancel()
      end
    end

    private

    def create_queues
      @exchanges.each do |ex, config|
        config[:queue] = EM::Queue.new
        Arke::Log.debug "ID:#{id} Created queue for #{ex}"
      end
    end

    def clear_queue(ex)
      until @exchanges[ex][:queue].empty?
        @exchanges[ex][:queue].pop do |action|
          Arke::Log.debug "ID:#{id} Clearing action #{action}"
        end
      end
      Arke::Log.debug "ID:#{id} Cleared queue for #{ex}"
    end

    def execute
      Fiber.new { yield }.resume
    end

    def schedule(action)
      case action.type
      when :order_create
        execute do
          order = action.params[:order]
          Arke::Log.info "ID:#{id} Creating order: #{order}"
          order = action.params[:order]
          price = apply_precision(order.price, action.destination.quote_precision)
          amount = apply_precision(order.amount, action.destination.base_precision.to_f,
            order.side == :sell ? action.destination.min_ask_amount.to_f : action.destination.min_bid_amount.to_f)
          begin
            response = action.destination.create_order(Arke::Order.new(order.market, price, amount, order.side))
            if response.respond_to?(:status) && response.status >= 300
              Log.warn "ID:#{id} Failed to create order #{order} status:#{response.status}(#{response.reason_phrase}) body:#{response.body}"
            end
          rescue StandardError
            Log.error "ID:#{id} #{$!}"
          end
        end
      when :order_stop
        execute do
          begin
            Arke::Log.info "ID:#{id} Canceling order: #{action.params}"
            action.destination.stop_order(action.params[:id])
          rescue StandardError
            Log.error "ID:#{id} #{$!}"
          end
        end
      else
        Arke::Log.error "ID:#{id} Unknown Action type: #{action.type}"
      end
    end
  end
end
