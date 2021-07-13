# frozen_string_literal: true

module Arke::Strategy
  # * aggregates one exchange orderbook to open one order per level (param: level_count)
  # * side: asks, bids, both (default: both)
  # * it adds a spread in percentage (param: spread)
  # * it updates open orders every period
  # * when an order matches it buys the liquidity on the source exchange
  class Copy < Base
    include ::Arke::Helpers::PricePoints
    include ::Arke::Helpers::Spread

    def initialize(sources, target, config, reactor)
      super
      params = @config["params"] || {}
      @levels_price_step = params["levels_price_step"]&.to_d || params["levels_size"]&.to_d
      @levels_price_func = params["levels_price_func"] || "constant"
      @levels_count = params["levels_count"].to_i
      @spread_bids = params["spread_bids"].to_d
      @spread_asks = params["spread_asks"].to_d
      @side_asks = %w[asks both].include?(@side)
      @side_bids = %w[bids both].include?(@side)

      @plugins = {
        limit_balance: Arke::Plugin::LimitBalance.new(target.account, target.base, target.quote, params)
      }

      check_config(params)

      @limit_asks_base_applied = @plugins[:limit_balance].limit_asks_base
      @limit_bids_base_applied = @plugins[:limit_balance].limit_bids_base

      config_markets
    end

    def check_config(params)
      raise "levels_price_step must be higher than zero" if @levels_price_step.nil? || @levels_price_step <= 0
      raise "levels_count must be minimum 1" if @levels_count.nil? || @levels_count < 1
      raise "spread_bids must be higher than zero" if @spread_bids.negative?
      raise "spread_asks must be higher than zero" if @spread_asks.negative?
      raise "side must be asks, bids or both" if !@side_asks && !@side_bids
    end

    def limit_asks_base
      @limit_asks_base_applied
    end

    def limit_bids_base
      @limit_bids_base_applied
    end

    def config_markets
      sources.each do |s|
        s.apply_flags(::Arke::Helpers::Flags::LISTEN_PUBLIC_ORDERBOOK)
        s.account.add_market_to_listen(s.id)
      end
    end

    def call
      raise "This strategy supports only one exchange source" if sources.size > 1

      assert_currency_found(target.account, target.base)
      assert_currency_found(target.account, target.quote)

      if fx
        orderbook = fx.apply_ob(source.orderbook)
      else
        orderbook = source.orderbook
      end

      limit = @plugins[:limit_balance].call(orderbook)
      limit_bids_base_applied = limit[:limit_bids_base]
      limit_asks_base_applied = limit[:limit_asks_base]
      limit_bids_quote = limit[:limit_bids_quote]
      limit_asks_quote = limit[:limit_asks_quote]
      top_bid_price = limit[:top_bid_price]
      top_ask_price = limit[:top_ask_price]

      price_points_asks = @side_asks ? price_points(:asks, top_ask_price, @levels_count, @levels_price_func, @levels_price_step) : nil
      price_points_bids = @side_bids ? price_points(:bids, top_bid_price, @levels_count, @levels_price_func, @levels_price_step) : nil
      ob_agg = orderbook.aggregate(price_points_bids, price_points_asks, target.min_amount)
      ob = ob_agg.to_ob

      ob_adjusted = ob.adjust_volume(
        limit_bids_base_applied,
        limit_asks_base_applied,
        limit_bids_quote,
        limit_asks_quote
      )
      ob_spread = ob_adjusted.spread(@spread_bids, @spread_asks)

      price_points_asks = price_points_asks&.map {|pp| ::Arke::PricePoint.new(apply_spread(:sell, pp.price_point, @spread_asks)) }
      price_points_bids = price_points_bids&.map {|pp| ::Arke::PricePoint.new(apply_spread(:buy, pp.price_point, @spread_bids)) }

      # Save the applied amount for scheduler.
      @limit_bids_base_applied = limit_bids_base_applied
      @limit_asks_base_applied = limit_asks_base_applied

      push_debug("0_levels_count", @levels_count)
      push_debug("0_levels_price_step", @levels_price_step)
      push_debug("0_top_ask", top_ask_price)
      push_debug("0_top_bid", top_bid_price)
      push_debug("0_asks_price_points", price_points_asks.inspect)
      push_debug("0_bids_price_points", price_points_bids.inspect)
      push_debug("1_ob_agg", "\n#{ob_agg}")
      push_debug("2_ob", "\n#{ob}")
      push_debug("3_ob_adjusted", "\n#{ob_adjusted}")
      push_debug("4_ob_spread", "\n#{ob_spread}")
      [ob_spread, {asks: price_points_asks, bids: price_points_bids}]
    end
  end
end
