# frozen_string_literal: true

module Arke::Strategy
  # * aggregates one exchange orderbook to open one order per level (param: level_count)
  # * side: asks, bids, both (default: both)
  # * it adds a spread in percentage (param: spread)
  # * it updates open orders every period
  # * when an order matches it buys the liquidity on the source exchange
  class Orderback < Base
    include Arke::Helpers::Splitter
    include Arke::Helpers::Spread

    DEFAULT_ORDERBACK_GRACE_TIME = 0.01

    def initialize(sources, target, config, reactor)
      super
      params = @config["params"] || {}
      @levels_size = params["levels_size"].to_f
      @levels_count = params["levels_count"].to_i
      @spread_bids = params["spread_bids"].to_f
      @spread_asks = params["spread_asks"].to_f
      @limit_asks_base = params["limit_asks_base"].to_f
      @limit_bids_base = params["limit_bids_base"].to_f
      @side_asks = %w[asks both].include?(@side)
      @side_bids = %w[bids both].include?(@side)
      @enable_orderback = params["enable_orderback"] ? true : false
      @min_order_back_amount = params["min_order_back_amount"].to_f
      @orderback_timer = params["orderback_timer"] || DEFAULT_ORDERBACK_GRACE_TIME
      Arke::Log.info "min order back amount: #{@min_order_back_amount}"
      Arke::Log.info "Initializing #{self.class} strategy with order_back #{@enable_orderback ? 'enabled' : 'disabled'}"
      register_callbacks
      @trades = {}
    end

    def register_callbacks
      target.account.register_on_trade_cb(&method(:notify_trade))
    end

    def notify_trade(trade)
      return if @enable_orderback == false || trade.market.upcase != target.id.upcase

      order_buy = target.open_orders.get_by_id(:buy, trade.order_id)
      order_sell = target.open_orders.get_by_id(:sell, trade.order_id)

      if order_buy && order_sell
        Arke::Log.error "ID:#{id} one order made a trade ?! order id:#{ trade.order_id }"
        return
      end
      order_back(trade, order_buy) if order_buy
      order_back(trade, order_sell) if order_sell
    end

    def order_back(trade, order)
      Arke::Log.info("ID:#{id} Trade on #{trade.market}, #{order.side} price: #{trade.price} amount: #{trade.volume}")
      spread = order.side == :sell ? @spread_asks : @spread_bids
      price = apply_spread(order.side, trade.price, -spread)
      type = order.side == :sell ? :buy : :sell

      Arke::Log.info("ID:#{id} Buffering order back #{trade.market}, #{type} price: #{price} amount: #{trade.volume}")
      @trades[trade.id] ||= {}
      @trades[trade.id][trade.order_id] = [trade.market, price, trade.volume, type]

      @timer ||= EM::Synchrony.add_timer(@orderback_timer) do
        grouped_trades = group_trades(@trades)
        orders = []
        actions = []
        grouped_trades.each do |k, v|
          order = Arke::Order.new(target.id, k[0].to_f, v, k[1].to_sym)
          if order.amount > @min_order_back_amount
            Arke::Log.info("ID:#{id} Pushing order back #{order} (min order back amount: #{@min_order_back_amount})")
            orders << order
          else
            Arke::Log.info("ID:#{id} Discard order back #{order} (min order back amount: #{@min_order_back_amount})")
          end
        end

        orders.each do |order|
          actions << Arke::Action.new(:order_create, source, order: order)
        end
        target.account.executor.push(actions)
        @timer = nil
        @trades = {}
      end
    end

    def group_trades(trades)
      group = {}
      trades.each do |_, trades_by_orders|
        trades_by_orders.each do |_, t|
          _, price, amount, type = t
          k = [price, type]
          group[k] ||= 0.0
          group[k] += amount
        end
      end
      group
    end

    def call
      raise "This strategy supports only one exchange source" if sources.size > 1

      assert_currency_found(source.account, source.base)
      assert_currency_found(source.account, source.quote)
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
      ob_spread = ob.spread(@spread_bids, @spread_asks)

      limit_asks_quote = source.account.balance(source.quote)["free"]
      limit_bids_quote = target.account.balance(target.quote)["total"]

      source_base_free = source.account.balance(source.base)["free"]
      target_base_total = target.account.balance(target.base)["total"]

      if source_base_free < @limit_bids_base
        limit_bids_base = source_base_free
        Arke::Log.warn("#{source.base} balance on #{source.account.driver} is #{source_base_free} lower then the limit set to #{@limit_bids_base}")
      else
        limit_bids_base = @limit_bids_base
      end

      if target_base_total < @limit_asks_base
        limit_asks_base = target_base_total
        Arke::Log.warn("#{target.base} balance on #{target.account.driver} is #{target_base_total} lower then the limit set to #{@limit_asks_base}")
      else
        limit_asks_base = @limit_asks_base
      end

      ob_adjusted = ob_spread.adjust_volume(
        limit_bids_base,
        limit_asks_base,
        limit_bids_quote,
        limit_asks_quote
      )

      push_debug("0_asks_price_points", price_points_asks)
      push_debug("0_bids_price_points", price_points_bids)
      push_debug("1_ob_agg", ob_agg)
      push_debug("2_ob", ob)
      push_debug("3_ob_spread", ob_spread)
      push_debug("4_ob_adjusted", ob_adjusted)

      ob_adjusted
    end
  end
end
