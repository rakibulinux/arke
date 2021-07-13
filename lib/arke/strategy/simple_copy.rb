# frozen_string_literal: true

module Arke::Strategy
  class SimpleCopy < Base
    include ::Arke::Helpers::Spread
    attr_reader :limit_asks_base
    attr_reader :limit_bids_quote

    def initialize(sources, target, config, reactor)
      super
      params = @config["params"] || {}
      @levels_price_step = params["levels_price_step"]&.to_d || params["levels_size"]&.to_d
      @levels_price_func = params["levels_price_func"] || "constant"
      @levels_count = params["levels_count"].to_i
      @spread_bids = params["spread_bids"].to_d
      @spread_asks = params["spread_asks"].to_d
      @random = (params["random"]&.to_d || 0.3).to_d
      @shape = params["shape"] || "W"
      @levels = params["levels"]

      balance_perc = params["balance_perc"]&.to_d || "0.8".to_d
      @balance_base_perc = params["balance_base_perc"]&.to_d || balance_perc
      @balance_quote_perc = params["balance_quote_perc"]&.to_d || balance_perc

      logger.info "ID:#{id} levels_price_step: %.2f" % [@levels_price_step]
      logger.info "ID:#{id} levels_count: %.0f" % [@levels_count]
      logger.info "ID:#{id} spread_bids: %.2f%%" % [@spread_bids * 100]
      logger.info "ID:#{id} spread_asks: %.2f%%" % [@spread_asks * 100]
      logger.info "ID:#{id} balance_base_perc: %.0f%%" % [@balance_base_perc * 100]
      logger.info "ID:#{id} balance_quote_perc: %.0f%%" % [@balance_quote_perc * 100]
      logger.info "ID:#{id} random: %.0f%%" % [@random * 100]
      logger.info "ID:#{id} shape: #{@shape}"
      logger.info "ID:#{id} levels: #{@levels}"
      check_config
      config_markets
    end


    def check_config
      raise "levels_price_step must be higher than zero" if @levels_price_step <= 0
      raise "levels_count must be minimum 1" if @levels_count < 1
      raise "levels must be an array" if !@levels.nil? && !@levels.is_a?(Array)
      raise "spread_bids must be higher than zero" if @spread_bids.negative?
      raise "spread_asks must be higher than zero" if @spread_asks.negative?
      raise "balance_perc or balance_base_perc must be higher than zero" if @balance_base_perc <= 0
      raise "balance_perc or balance_quote_perc must be higher than zero" if @balance_quote_perc <= 0
      raise "balance_perc or balance_base_perc must lower than one" if @balance_base_perc > 1
      raise "balance_perc or balance_quote_perc must lower than one" if @balance_quote_perc > 1
    end

    def config_markets
      sources.each do |s|
        s.apply_flags(::Arke::Helpers::Flags::LISTEN_PUBLIC_ORDERBOOK)
        s.account.add_market_to_listen(s.id)
      end
    end

    def set_liquidity_limits
      balance_quote = target.account.balance(target.quote)&.fetch("total")
      balance_base = target.account.balance(target.base)&.fetch("total")

      raise "ID:#{id} No balance found for currency #{target.quote}" unless balance_quote
      raise "ID:#{id} No balance found for currency #{target.base}" unless balance_base

      @limit_asks_base = balance_base * @balance_base_perc
      @limit_bids_quote = balance_quote * @balance_quote_perc

      logger.info "ID:#{id} limit_asks_base: #{limit_asks_base}"
      logger.info "ID:#{id} limit_bids_quote: #{limit_bids_quote}"
    end

    # 1. get the account balance, calculate limit_asks_base and limit_bids_quote
    # 2. calculate mid price from source orderbook
    # 3. generate a target orderbook with a defined shape (with random factor)
    def call
      raise "This strategy supports only one exchange source" if sources.size > 1

      assert_currency_found(target.account, target.base)
      assert_currency_found(target.account, target.quote)

      if fx
        raise "FX Rate is not ready" unless fx.rate

        if sources.size == 0
          mp = fx.rate
        else
          mp = apply_fx(source.mid_price())
        end
      else
        mp = source.mid_price()
      end

      set_liquidity_limits()

      opts = {
        shape:             @shape,
        levels:            @levels,
        levels_count:      @levels_count,
        levels_price_step: @levels_price_step,
        levels_price_func: @levels_price_func,
        random:            @random,
        market:            target.id,
        best_ask_price:    apply_spread(:sell, mp, @spread_asks),
        best_bid_price:    apply_spread(:buy, mp, @spread_bids),
      }
      ob, pps = ::Arke::Orderbook::Generator.new.generate(opts)

      ob_adjusted = ob.adjust_volume_simple(
        @limit_asks_base,
        @limit_bids_quote
      )

      push_debug("0_levels_count", @levels_count)
      push_debug("0_levels_price_step", @levels_price_step)
      push_debug("0_mid_price", mp)
      push_debug("2_ob", "\n#{ob}")
      push_debug("3_ob_adjusted", "\n#{ob_adjusted}")

      [ob_adjusted, pps]
    end
  end
end
