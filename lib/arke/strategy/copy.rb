# frozen_string_literal: true

module Arke::Strategy
  # * aggregates one exchange orderbook to open one order per level (param: level_count)
  # * side: asks, bids, both (default: both)
  # * it adds a spread in percentage (param: spread)
  # * it updates open orders every period
  # * when an order matches it buys the liquidity on the source exchange
  class Copy < Base
    include ::Arke::Helpers::Splitter
    include ::Arke::Helpers::Spread
    attr_reader :limit_asks_base
    attr_reader :limit_bids_base

    def initialize(sources, target, config, reactor)
      super
      params = @config["params"] || {}
      @levels_price_size = params["levels_price_size"]&.to_d || params["levels_size"]&.to_d
      @levels_count = params["levels_count"].to_i
      @spread_bids = params["spread_bids"].to_d
      @spread_asks = params["spread_asks"].to_d
      @limit_asks_base = params["limit_asks_base"].to_d
      @limit_bids_base = params["limit_bids_base"].to_d
      @side_asks = %w[asks both].include?(@side)
      @side_bids = %w[bids both].include?(@side)
      check_config
    end

    def check_config
      raise "levels_price_size must be higher than zero" if @levels_price_size <= 0
      raise "levels_count must be minimum 1" if @levels_count < 1
      raise "spread_bids must be higher than zero" if @spread_bids.negative?
      raise "spread_asks must be higher than zero" if @spread_asks.negative?
      raise "limit_asks_base must be higher than zero" if limit_asks_base <= 0
      raise "limit_bids_base must be higher than zero" if limit_bids_base <= 0
      raise "side must be asks, bids or both" if !@side_asks && !@side_bids
    end

    def call
      raise "This strategy supports only one exchange source" if sources.size > 1

      assert_currency_found(target.account, target.base)
      assert_currency_found(target.account, target.quote)

      split_opts = {
        step_size: @levels_price_size,
      }

      top_ask = source.orderbook[:sell].first
      top_bid = source.orderbook[:buy].first
      raise "Source order book is empty" if top_ask.nil? || top_bid.nil?

      price_points_asks = @side_asks ? split_constant_pp(:asks, top_ask.first, @levels_count, split_opts) : nil
      price_points_bids = @side_bids ? split_constant_pp(:bids, top_bid.first, @levels_count, split_opts) : nil
      ob_agg = source.orderbook.aggregate(price_points_bids, price_points_asks, target.min_amount)
      ob = ob_agg.to_ob

      limit_asks_quote = nil
      limit_bids_quote = target.account.balance(target.quote)["total"]

      target_base_total = target.account.balance(target.base)["total"]

      if target_base_total < limit_asks_base
        limit_asks_base_applied = target_base_total
        logger.warn("#{target.base} balance on #{target.account.driver} is #{target_base_total} lower than the limit set to #{@limit_asks_base}")
      else
        limit_asks_base_applied = limit_asks_base
      end

      ob_adjusted = ob.adjust_volume(
        limit_bids_base,
        limit_asks_base_applied,
        limit_bids_quote,
        limit_asks_quote
      )
      ob_spread = ob_adjusted.spread(@spread_bids, @spread_asks)

      price_points_asks = price_points_asks&.map {|pp| ::Arke::PricePoint.new(apply_spread(:sell, pp.price_point, @spread_asks)) }
      price_points_bids = price_points_bids&.map {|pp| ::Arke::PricePoint.new(apply_spread(:buy, pp.price_point, @spread_bids)) }

      push_debug("0_levels_count", @levels_count)
      push_debug("0_levels_price_size", @levels_price_size)
      push_debug("0_top_ask", top_ask&.first)
      push_debug("0_top_bid", top_bid&.first)
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
