# frozen_string_literal: true

module Arke::Strategy
  class Circuitbraker < Base
    include ::Arke::Helpers::Spread

    def initialize(sources, target, config, reactor)
      super
      params = @config["params"] || {}
      @spread_bids = params["spread_bids"].to_f
      @spread_asks = params["spread_asks"].to_f
      check_config
    end

    def check_config
      raise "spread_bids must be higher than zero" if @spread_bids.negative?
      raise "spread_asks must be higher than zero" if @spread_asks.negative?
    end

    def call
      raise "This strategy supports only one exchange source" if sources.size > 1

      assert_currency_found(target.account, target.base)
      assert_currency_found(target.account, target.quote)

      top_ask = source.orderbook[:sell].first&.first
      top_bid = source.orderbook[:buy].first&.first
      raise "Source order book is empty" if top_ask.nil? || top_bid.nil?

      limit_best_sell = apply_spread(:sell, top_ask, @spread_asks)
      limit_best_buy = apply_spread(:buy, top_bid, @spread_bids)

      push_debug("0_top_ask", top_ask)
      push_debug("0_top_bid", top_bid)
      push_debug("1_limit_best_sell", limit_best_sell)
      push_debug("1_limit_best_buy", limit_best_buy)

      opts = {price_levels: []}
      scheduler = Arke::Scheduler::Smart.new(target.open_orders, nil, target, opts)
      actions = []
      actions += scheduler.cancel_risky_orders(:sell, limit_best_sell)
      actions += scheduler.cancel_risky_orders(:buy, limit_best_buy)
      actions.sort_by!(&:priority)
      actions.reverse!

      target.account.executor.push(actions) unless actions.empty?

      [nil, nil]
    end
  end
end
