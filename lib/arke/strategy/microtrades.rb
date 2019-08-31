module Arke::Strategy
  # * create random market orders
  # * the order amount is randomly from the min amount of the market to 2 times the min amount
  class Microtrades < Base
    include Arke::Helpers::Precision
    include Arke::Helpers::Spread
    class EmptyOrderBook < StandardError; end

    Sides = {"asks" => :sell, "bids" => :buy, "both" => "both"}

    def initialize(sources, target, config, executor, reactor)
      super
      params = @config["params"] || {}
      market_infos = target.get_market_infos
      @min_amount = (params["min_amount"] ? params["min_amount"] : target_min_amount(market_infos)).to_f
      @max_amount = (params["max_amount"] ? params["max_amount"] : @min_amount * 2).to_f
      @min_price = params["min_price"]
      @max_price = params["max_price"]
      @linked_strategy_id = params["linked_strategy_id"]
      if @linked_strategy_id
        @price_difference = params["price_difference"] || 0.02
      end
      @enable_orderback = false
      @sides = Sides[@side]
      Arke::Log.info "ID:#{id} Market infos: #{market_infos}"
      Arke::Log.info "ID:#{id} Min amount: #{@min_amount}"
      Arke::Log.info "ID:#{id} Max amount: #{@max_amount}"
      raise "min amount must not be zero" if @min_amount == 0
      raise "max amount must not be zero" if @max_amount == 0
    end

    def delay_the_first_execute
      true
    end

    def target_min_amount(market_infos)
      [
        market_infos["min_ask_amount"],
        market_infos["min_bid_amount"],
        target.min_ask_amount,
        target.min_bid_amount,
      ].map(&:to_f).select{|a| a != 0}.min
    end

    def get_amount(side)
      side_min_value = (side == :sell) ? target.min_ask_amount.to_f : target.min_bid_amount.to_f
      amount = rand(@min_amount..@max_amount)
      apply_precision(amount, target.base_precision.to_f, side_min_value)
    end

    def get_price(side)
      if @linked_strategy_id
        linked_strategy = @reactor.find_strategy(@linked_strategy_id)
        top_ask = linked_strategy.sources.first.orderbook[:sell].first
        top_bid = linked_strategy.sources.first.orderbook[:buy].first
        if [top_ask, top_bid].include?(nil)
          raise EmptyOrderBook.new("Linked strategy orderbook is empty (top_ask:#{top_ask} top_bid: #{top_bid})")
        end
        price = side == :buy ? top_ask.first : top_bid.first
        #FIXME: use absolute value
        price = apply_spread(side, price, @price_difference * -1)
      else
        price = side == :buy ? @max_price : @min_price
      end
      apply_precision(price, target.quote_precision.to_f)
    end

    def call
      Fiber.new do
        begin
          side = @sides == "both" ? [:buy, :sell].sample : @sides
          order = Arke::Order.new(target.market, get_price(side), get_amount(side), side)
          Arke::Log.warn "ID:#{id} Creating order #{order}"
          target.create_order(order)
          Arke::Log.warn "ID:#{id} Created order #{order}"
          EM::Synchrony.sleep(0.1)
          target.stop_order(order.id)
        rescue StandardError => e
          Arke::Log.error "ID:#{id} #{e}"
          Arke::Log.error "#{e.backtrace.join("\n")}"
        end
      end.resume
      nil
    end
  end
end
