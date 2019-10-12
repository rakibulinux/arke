module Arke::Strategy
  # * aggregates one exchange orderbook to open one order per level (param: level_count)
  # * side: asks, bids, both (default: both)
  # * it adds a spread in percentage (param: spread)
  # * it updates open orders every period
  # * when an order matches it buys the liquidity on the source exchange
  class Fixedprice < Base
    include Arke::Helpers::Splitter
    include Arke::Helpers::Spread

    def initialize(sources, target, config, executor, reactor)
      super
      params = @config["params"] || {}
      @levels_size = params["levels_size"].to_f
      @levels_count = params["levels_count"].to_i
      @price = params["price"].to_f
      @random_delta = params["random_delta"].to_f
      @spread_bids = params["spread_bids"].to_f
      @spread_asks = params["spread_asks"].to_f
      @limit_asks_base = params["limit_asks_base"].to_f
      @limit_bids_base = params["limit_bids_base"].to_f

      @side_asks = %w[asks both].include?(@side)
      @side_bids = %w[bids both].include?(@side)

      @min_amount = (params["min_amount"] || 0.001).to_f
      @max_amount = (params["max_amount"] || 1.0).to_f

      raise "Price must not be zero" if @price == 0
      Arke::Log.info "Initializing #{self.class} strategy with order_back #{@enable_orderback ? "enabled": "disabled"}"
    end

    def call
      raise "This strategy doesn't support sources" if sources.size != 0

      assert_currency_found(target, target.base)
      assert_currency_found(target, target.quote)

      delta = rand(0..@random_delta) - (@random_delta / 2)
      top_ask = top_bid = @price + delta

      price_points_asks = @side_asks ? split_constant(:asks, top_ask, @levels_count, step_size: @levels_size) : nil
      price_points_bids = @side_bids ? split_constant(:bids, top_bid, @levels_count, step_size: @levels_size) : nil

      sell = ::RBTree[price_points_asks.map {|price| [price, rand(@min_amount..@max_amount)] }] if price_points_asks
      buy  = ::RBTree[price_points_bids.map {|price| [price, rand(@min_amount..@max_amount)] }] if price_points_bids

      ob = Arke::Orderbook::Orderbook.new(
        target.market,
        sell:             sell || ::RBTree.new,
        buy:              buy || ::RBTree.new,
        volume_bids_base: price_points_bids ? price_points_bids.size : 0,
        volume_asks_base: price_points_asks ? price_points_asks.size : 0
      )
      ob_spread = ob.spread(@spread_bids, @spread_asks)

      limit_bids_quote = target.balance(target.quote)["total"]
      target_base_total = target.balance(target.base)["total"]
      limit_bids_base = @limit_bids_base

      if target_base_total < @limit_asks_base
        limit_asks_base = target_base_total
        Arke::Log.warn("#{target.base} balance on #{target.driver} is #{target_base_total} lower then the limit set to #{@limit_asks_base}")
      else
        limit_asks_base = @limit_asks_base
      end

      ob_adjusted = ob_spread.adjust_volume(
        limit_bids_base,
        limit_asks_base,
        limit_bids_quote,
      )

      push_debug("0_asks_price_points", price_points_asks)
      push_debug("0_bids_price_points", price_points_bids)
      push_debug("1_ob", ob)
      push_debug("2_ob_spread", ob_spread)
      push_debug("3_ob_adjusted", ob_adjusted)

      ob_adjusted
    end
  end
end
