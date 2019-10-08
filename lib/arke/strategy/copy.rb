module Arke::Strategy
  # * aggregates one exchange orderbook to open one order per level (param: level_count)
  # * side: asks, bids, both (default: both)
  # * it adds a spread in percentage (param: spread)
  # * it updates open orders every period
  # * when an order matches it buys the liquidity on the source exchange
  class Copy < Base
    include Arke::Helpers::Splitter
    include Arke::Helpers::Spread

    def initialize(sources, target, config, reactor)
      super
      params = @config["params"] || {}
      @levels_size = params["levels_size"].to_f
      @levels_count = params["levels_count"].to_i
      @spread_bids = params["spread_bids"].to_f
      @spread_asks = params["spread_asks"].to_f
      @limit_asks_base = params["limit_asks_base"].to_f
      @limit_bids_base = params["limit_bids_base"].to_f
      @side_asks = %w{asks both}.include?(@side)
      @side_bids = %w{bids both}.include?(@side)
    end

    def call
      raise "This strategy supports only one exchange source" if sources.size > 1

      assert_currency_found(target.account, target.base)
      assert_currency_found(target.account, target.quote)
      split_opts = {
        step_size: @levels_size,
      }
      top_ask = source.orderbook[:sell].first
      top_bid = source.orderbook[:buy].first
      price_points_asks = @side_asks ? split_constant(:asks, top_ask.first, @levels_count, split_opts) : nil
      price_points_bids = @side_bids ? split_constant(:bids, top_bid.first, @levels_count, split_opts) : nil
      ob_agg = source.orderbook.aggregate(price_points_bids, price_points_asks)
      ob = ob_agg.to_ob

      limit_asks_quote = nil
      limit_bids_quote = target.account.balance(target.quote)["total"]

      target_base_total = target.account.balance(target.base)["total"]
      limit_bids_base = @limit_bids_base

      if target_base_total < @limit_asks_base
        limit_asks_base = target_base_total
        Arke::Log.warn("#{target.base} balance on #{target.driver} is #{target_base_total} lower then the limit set to #{@limit_asks_base}")
      else
        limit_asks_base = @limit_asks_base
      end

      ob_adjusted = ob.adjust_volume(
        limit_bids_base,
        limit_asks_base,
        limit_bids_quote,
        limit_asks_quote
      )
      ob_spread = ob_adjusted.spread(@spread_bids, @spread_asks)

      push_debug("0_asks_price_points", price_points_asks)
      push_debug("0_bids_price_points", price_points_bids)
      push_debug("1_ob_agg", "\n#{ob_agg}")
      push_debug("2_ob", "\n#{ob}")
      push_debug("3_ob_adjusted", "\n#{ob_adjusted}")
      push_debug("4_ob_spread", "\n#{ob_spread}")

      ob_adjusted
    end
  end
end
