# frozen_string_literal: true

module Arke::Strategy
  # * aggregates one exchange orderbook to open one order per level (param: level_count)
  # * side: asks, bids, both (default: both)
  # * it adds a spread in percentage (param: spread)
  # * it updates open orders every period
  # * when an order matches it buys the liquidity on the source exchange
  class Fixedprice < Base
    include Arke::Helpers::Splitter
    include Arke::Helpers::Spread

    def initialize(sources, target, config, reactor)
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
      raise "Price must not be zero" if @price.zero?

      Arke::Log.info "Initializing #{self.class} strategy with order_back #{@enable_orderback ? 'enabled' : 'disabled'}"
    end

    def call
      raise "This strategy doesn't support sources" unless sources.empty?

      assert_currency_found(target.account, target.base)
      assert_currency_found(target.account, target.quote)
      split_opts = {
        step_size: @levels_size,
      }

      delta = rand(0..@random_delta) - (@random_delta / 2)
      top_ask = top_bid = @price + delta
      price_points_asks = @side_asks ? split_constant(:asks, top_ask, @levels_count, split_opts) : []
      price_points_bids = @side_bids ? split_constant(:bids, top_bid, @levels_count, split_opts) : []
      volume_asks_base = 0.0
      volume_bids_base = 0.0
      default_ask_amount = @limit_asks_base / @levels_count
      default_bid_amount = @limit_bids_base / @levels_count
      ob_asks = price_points_asks.map do |price|
        volume_asks_base += default_ask_amount
        [price, default_ask_amount]
      end
      ob_bids = price_points_bids.map do |price|
        volume_bids_base += default_bid_amount
        [price, default_bid_amount]
      end
      ob = Arke::Orderbook::Orderbook.new(
        target.id,
        sell:             price_points_asks ? ::RBTree[ob_asks] : ::RBTree.new,
        buy:              price_points_bids ? ::RBTree[ob_bids] : ::RBTree.new,
        volume_asks_base: volume_asks_base,
        volume_bids_base: volume_bids_base,
      )
      ob_spread = ob.spread(@spread_bids, @spread_asks)

      limit_bids_quote = target.account.balance(target.quote)["total"]
      target_base_total = target.account.balance(target.base)["total"]
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
        limit_bids_quote
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
