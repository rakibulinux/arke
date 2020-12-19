# frozen_string_literal: true

module Arke::Strategy
  # * create an orderbook to open one order per level (param: level_count)
  # * side: asks, bids, both (default: both)
  # * it adds a spread in percentage (param: spread)
  # * it updates open orders every period
  # * when an order matches it buys the liquidity on the source exchange
  class SimpleCopy < Base
    include ::Arke::Helpers::Splitter
    include ::Arke::Helpers::Spread
    attr_reader :limit_asks
    attr_reader :limit_bids

    def initialize(sources, target, config, reactor)
      super
      params = @config["params"] || {}
      @levels_price_size = params["levels_price_size"]&.to_d || params["levels_size"]&.to_d
      @levels_count = params["levels_count"].to_i
      @spread_bids = params["spread_bids"].to_d
      @spread_asks = params["spread_asks"].to_d
      @random = (params["random"]&.to_d || 0.3).to_d
      @shape = params["shape"] || "W"
      @levels = params["levels"]

      balance_perc = params["balance_perc"]&.to_d || 1.to_d
      @balance_base_perc = params["balance_base_perc"]&.to_d || balance_perc
      @balance_quote_perc = params["balance_quote_perc"]&.to_d || balance_perc

      logger.info "ID:#{id} levels_price_size: %.2f" % [@levels_price_size]
      logger.info "ID:#{id} levels_count: %.0f" % [@levels_count]
      logger.info "ID:#{id} spread_bids: %.0f%%" % [@spread_bids * 100]
      logger.info "ID:#{id} spread_asks: %.0f%%" % [@spread_asks * 100]
      logger.info "ID:#{id} balance_base_perc: %.0f%%" % [@balance_base_perc * 100]
      logger.info "ID:#{id} balance_quote_perc: %.0f%%" % [@balance_quote_perc * 100]
      logger.info "ID:#{id} random: %.0f%%" % [@random * 100]
      logger.info "ID:#{id} shape: #{@shape}"
      logger.info "ID:#{id} levels: #{@levels}"

      # @side_asks = %w[asks both].include?(@side)
      # @side_bids = %w[bids both].include?(@side)
      check_config
    end

    def check_config
      raise "levels_price_size must be higher than zero" if @levels_price_size <= 0
      raise "levels_count must be minimum 1" if @levels_count < 1
      raise "levels must be an array" if !@levels.nil? && !@levels.is_a?(Array)
      raise "spread_bids must be higher than zero" if @spread_bids.negative?
      raise "spread_asks must be higher than zero" if @spread_asks.negative?
      raise "balance_perc or balance_base_perc must be higher than zero" if @balance_base_perc <= 0
      raise "balance_perc or balance_quote_perc must be higher than zero" if @balance_quote_perc <= 0
      raise "balance_perc or balance_base_perc must lower than one" if @balance_base_perc > 1
      raise "balance_perc or balance_quote_perc must lower than one" if @balance_quote_perc > 1
      # raise "side must be asks, bids or both" if !@side_asks && !@side_bids
    end

    def mid_price
      top_ask = source.orderbook[:sell].first
      top_bid = source.orderbook[:buy].first
      raise "Source orderbook is empty" if top_ask.nil? || top_bid.nil?

      (top_ask.first + top_bid.first) / 2
    end

    def set_liquidity_limits
      balance_quote = target.account.balance(target.quote)&.fetch("total")
      balance_base = target.account.balance(target.base)&.fetch("total")

      raise "ID:#{id} No balance found for currency #{target.quote}" unless balance_quote
      raise "ID:#{id} No balance found for currency #{target.base}" unless balance_base

      @limit_asks = balance_base * @balance_base_perc
      @limit_bids = balance_quote * @balance_quote_perc
    end

    # 1. get the account balance, calculate limit_asks and limit_bids
    # 2. calculate mid price from source orderbook
    # 3. generate a target orderbook with a defined shape (with random factor)
    def call
      raise "This strategy supports only one exchange source" if sources.size > 1

      assert_currency_found(target.account, target.base)
      assert_currency_found(target.account, target.quote)

      mp = mid_price()
      set_liquidity_limits()

      opts = {
        shape:             @shape,
        levels:            @levels,
        levels_count:      @levels_count,
        levels_price_size: @levels_price_size,
        random:            @random,
        market:            target.id,
        best_ask_price:    apply_spread(:sell, mp, @spread_asks),
        best_bid_price:    apply_spread(:buy, mp, @spread_bids),
      }
      ob, pps = ::Arke::Orderbook::Generator.generate(opts)

      ob_adjusted = ob.adjust_volume_simple(
        @limit_asks,
        @limit_bids
      )

      push_debug("0_levels_count", @levels_count)
      push_debug("0_levels_price_size", @levels_price_size)
      push_debug("0_mid_price", mp)
      push_debug("2_ob", "\n#{ob}")
      push_debug("3_ob_adjusted", "\n#{ob_adjusted}")

      [ob_adjusted, pps]
    end
  end
end
