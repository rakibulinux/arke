module Arke::Strategy
  # * create random market orders
  # * the order amount is randomly from the min amount of the market to 2 times the min amount
  class Microtrades < Base
    include Arke::Helpers::Precision

    def initialize(sources, target, config, executor)
      super
      params = @config["params"] || {}
      market_infos = target.get_market_infos
      @min_amount = (params["min_amount"] ? params["min_amount"] : target_min_amount(market_infos)).to_f
      @max_amount = (params["max_amount"] ? params["max_amount"] : @min_amount * 2).to_f
      @min_price = params["min_price"]
      @max_price = params["max_price"]
      @enable_orderback = false
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

    def call
      side = [:buy, :sell].sample
      side_min_value = (side == :sell) ? target.min_ask_amount.to_f : target.min_bid_amount.to_f
      amount = rand(@min_amount..@max_amount)
      amount = apply_precision(amount, target.base_precision.to_f, side_min_value)
      price = side == :buy ? @max_price : @min_price
      Fiber.new do
        begin
          order = Arke::Order.new(target.market, price, amount, side)
          Arke::Log.warn "ID:#{id} Creating order #{order}"
          target.create_order(order)
          Arke::Log.warn "ID:#{id} Created order #{order}"
          EM::Synchrony.sleep(0.1)
          target.stop_order(order.id)
        rescue StandardError
          Arke::Log.error "ID:#{id} #{$!}"
        end
      end.resume
      nil
    end
  end
end
