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
      @limit_asks_base = params["limit_asks_base"].to_d
      @limit_bids_base = params["limit_bids_base"].to_d
      @limit_asks_base_applied = @limit_asks_base
      @limit_bids_base_applied = @limit_bids_base
      @balance_base_perc = params["balance_base_perc"].to_d
      @balance_quote_perc = params["balance_quote_perc"].to_d
      @side_asks = %w[asks both].include?(@side)
      @side_bids = %w[bids both].include?(@side)
      check_config(params)
    end

    def check_config(params)
      raise "levels_price_step must be higher than zero" if @levels_price_step.nil? || @levels_price_step <= 0
      raise "levels_count must be minimum 1" if @levels_count.nil? || @levels_count < 1
      raise "spread_bids must be higher than zero" if @spread_bids.negative?
      raise "spread_asks must be higher than zero" if @spread_asks.negative?
      raise "limit_asks_base or balance_base_perc must be specified" unless params.key?("limit_asks_base") || params.key?("balance_base_perc")
      raise "limit_asks_base must be higher than zero" if params.key?("limit_asks_base") && @limit_asks_base <= 0
      raise "balance_base_perc must be higher than 0 to 1" if params.key?("balance_base_perc") && (@balance_base_perc <= 0 || @balance_base_perc > 1)
      raise "limit_bids_base or balance_quote_perc must be specified" unless params.key?("limit_bids_base") || params.key?("balance_quote_perc")
      raise "limit_bids_base must be higher than zero" if params.key?("limit_bids_base") && @limit_bids_base <= 0
      raise "balance_quote_perc must be higher than 0 to 1" if params.key?("balance_quote_perc") && (@balance_quote_perc <= 0 || @balance_quote_perc > 1)
      raise "side must be asks, bids or both" if !@side_asks && !@side_bids
    end
    
    def limit_asks_base
      @limit_asks_base_applied
    end

    def limit_bids_base
      @limit_bids_base_applied
    end

    def call
      raise "This strategy supports only one exchange source" if sources.size > 1

      assert_currency_found(target.account, target.base)
      assert_currency_found(target.account, target.quote)

      top_ask = source.orderbook[:sell].first
      top_bid = source.orderbook[:buy].first
      raise "Source order book is empty" if top_ask.nil? || top_bid.nil?

      top_ask_price = top_ask.first
      top_bid_price = top_bid.first
      mid_price = (top_ask_price + top_bid_price) / 2
      price_points_asks = @side_asks ? price_points(:asks, top_ask_price, @levels_count, @levels_price_func, @levels_price_step) : nil
      price_points_bids = @side_bids ? price_points(:bids, top_bid_price, @levels_count, @levels_price_func, @levels_price_step) : nil
      ob_agg = source.orderbook.aggregate(price_points_bids, price_points_asks, target.min_amount)
      ob = ob_agg.to_ob

      quote_balance = target.account.balance(target.quote)["total"]
      base_balance = target.account.balance(target.base)["total"]
      limit_bids_quote = quote_balance
      target_base_total = base_balance
      limit_asks_base_applied = @limit_asks_base
      limit_bids_base_applied = @limit_bids_base

      # Adjust bids/asks limit by balance ratio.
      if @balance_quote_perc > 0
        limit_bids_quote = quote_balance * @balance_quote_perc
        limit_bids_base_applied = limit_bids_quote / mid_price if @limit_bids_base == 0 
      end
      if @balance_base_perc > 0
        target_base_total = base_balance * @balance_base_perc
        limit_asks_base_applied = target_base_total if @limit_asks_base == 0 
      end

      # Adjust bids/asks limit if it exeeded the target (balance).
      if target_base_total < limit_asks_base_applied
        limit_asks_base_applied = target_base_total
        logger.warn("#{target.base} balance on #{target.account.driver} is #{target_base_total} lower than the limit set to #{@limit_asks_base}")
      end
      if limit_bids_quote < limit_bids_base_applied * mid_price
        limit_bids_base_applied = limit_bids_quote / mid_price
        logger.warn("#{target.base} balance on #{target.account.driver} is #{limit_bids_quote} lower than the limit set to #{@limit_bids_base}")
      end

      limit_asks_quote = target_base_total * mid_price

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
