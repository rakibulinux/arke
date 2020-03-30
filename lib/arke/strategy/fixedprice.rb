# frozen_string_literal: true

module Arke::Strategy
  # * aggregates one exchange orderbook to open one order per level (param: level_count)
  # * side: asks, bids, both (default: both)
  # * it adds a spread in percentage (param: spread)
  # * it updates open orders every period
  # * when an order matches it buys the liquidity on the source exchange
  class Fixedprice < Base
    include ::Arke::Helpers::Splitter
    include ::Arke::Helpers::Spread

    def initialize(sources, target, config, reactor)
      super
      params = @config["params"] || {}
      @levels_size = params["levels_size"].to_d
      @levels_count = params["levels_count"].to_i
      @price = params["price"].to_d
      @random_delta = params["random_delta"].to_d
      @spread_bids = params["spread_bids"].to_d
      @spread_asks = params["spread_asks"].to_d
      @limit_asks_base = params["limit_asks_base"].to_d
      @limit_bids_base = params["limit_bids_base"].to_d
      @side_asks = %w[asks both].include?(@side)
      @side_bids = %w[bids both].include?(@side)

      logger.info "Initializing #{self.class} strategy with order_back #{@enable_orderback ? 'enabled' : 'disabled'}"
      check_config
    end

    def check_config
      raise "ID:#{id} Price must not be zero" if @price.zero?
      raise "ID:#{id} levels_size is missing" unless @levels_size
      raise "ID:#{id} levels_count is missing" unless @levels_count
    end

    #
    # Volume formulas with linear repartition:
    #
    # (1) SumAmounts = MinAmount * LevelsCount + MaxAmount * LevelsCount / 2
    #
    # From (1) we can deduce (2):
    #
    # (2) MaxAmount = 2 * SumAmounts / LevelsCount - 2 * MinAmount
    #
    def call
      raise "This strategy doesn't support sources" unless sources.empty?

      assert_currency_found(target.account, target.base)
      assert_currency_found(target.account, target.quote)

      split_opts = {
        step_size: @levels_size,
      }

      delta = rand(0..@random_delta) - (@random_delta / 2)
      top_ask = top_bid = @price + delta
      price_points_asks = @side_asks ? split_constant_pp(:asks, top_ask, @levels_count, split_opts) : []
      price_points_bids = @side_bids ? split_constant_pp(:bids, top_bid, @levels_count, split_opts) : []
      volume_asks_base = 0.to_d
      volume_bids_base = 0.to_d

      max_amount_ask = 2.to_d * @limit_asks_base / @levels_count - 2 * target.min_amount
      max_amount_bid = 2.to_d * @limit_bids_base / @levels_count - 2 * target.min_amount

      max_amount_ask = target.min_amount if max_amount_ask.negative?
      max_amount_bid = target.min_amount if max_amount_bid.negative?

      ask_amounts = split_linear(nil, max_amount_ask, @levels_count, last_value: target.min_amount)
      bid_amounts = split_linear(nil, max_amount_bid, @levels_count, last_value: target.min_amount)

      ob_asks = price_points_asks.map do |pp|
        amount = ask_amounts.shift
        volume_asks_base += amount
        [pp.price_point, amount]
      end

      ob_bids = price_points_bids.map do |pp|
        amount = bid_amounts.shift
        volume_bids_base += amount
        [pp.price_point, amount]
      end

      ob = Arke::Orderbook::Orderbook.new(
        target.id,
        sell:             price_points_asks ? ::RBTree[ob_asks] : ::RBTree.new,
        buy:              price_points_bids ? ::RBTree[ob_bids] : ::RBTree.new,
        volume_asks_base: volume_asks_base,
        volume_bids_base: volume_bids_base
      )
      ob_spread = ob.spread(@spread_bids, @spread_asks)

      limit_bids_quote = target.account.balance(target.quote)["total"]
      target_base_total = target.account.balance(target.base)["total"]
      limit_bids_base = @limit_bids_base

      if target_base_total < @limit_asks_base
        limit_asks_base = target_base_total
        logger.warn("#{target.base} balance on #{target.account.driver} is #{target_base_total} lower than the limit set to #{@limit_asks_base}")
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

      [ob_adjusted, {asks: price_points_asks, bids: price_points_bids}]
    end
  end
end
