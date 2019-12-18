# frozen_string_literal: true

module Arke::Strategy
  # * aggregates one exchange orderbook to open one order per level (param: level_count)
  # * side: asks, bids, both (default: both)
  # * it adds a spread in percentage (param: spread)
  # * it updates open orders every period
  # * when an order matches it buys the liquidity on the source exchange
  class Orderback < Base
    include ::Arke::Helpers::Splitter
    include ::Arke::Helpers::Spread
    include ::Arke::Helpers::Flags
    attr_reader :limit_asks_base
    attr_reader :limit_bids_base

    DEFAULT_ORDERBACK_GRACE_TIME = 0.01

    def initialize(sources, target, config, reactor)
      super
      params = @config["params"] || {}
      @levels_size = params["levels_size"].to_d
      @levels_count = params["levels_count"].to_i
      @spread_bids = params["spread_bids"].to_d
      @spread_asks = params["spread_asks"].to_d
      @limit_asks_base = params["limit_asks_base"].to_d
      @limit_bids_base = params["limit_bids_base"].to_d
      @side_asks = %w[asks both].include?(@side)
      @side_bids = %w[bids both].include?(@side)

      @enable_orderback = params["enable_orderback"] ? true : false
      @min_order_back_amount = params["min_order_back_amount"].to_f
      @orderback_grace_time = params["orderback_grace_time"]&.to_f || DEFAULT_ORDERBACK_GRACE_TIME
      logger.info "min order back amount: #{@min_order_back_amount}"
      logger.info "Initializing #{self.class} strategy with order_back #{@enable_orderback ? 'enabled' : 'disabled'}"
      sources.each {|s| s.apply_flags(FETCH_PRIVATE_BALANCE) }
      register_callbacks
      check_config
      @trades = {}
    end

    def check_config
      raise "levels_size must be higher than zero" if @levels_size <= 0
      raise "levels_count must be minimum 1" if @levels_count <= 1
      raise "spread_bids must be higher than zero" if @spread_bids.negative?
      raise "spread_asks must be higher than zero" if @spread_asks.negative?
      raise "limit_asks_base must be higher than zero" if limit_asks_base <= 0
      raise "limit_bids_base must be higher than zero" if limit_bids_base <= 0
      raise "side must be asks, bids or both" if !@side_asks && !@side_bids
    end

    def register_callbacks
      target.account.register_on_private_trade_cb(&method(:notify_private_trade))
    end

    def notify_private_trade(trade)
      return if @enable_orderback == false || trade.market.upcase != target.id.upcase

      order_buy = target.open_orders.get_by_id(:buy, trade.order_id)
      order_sell = target.open_orders.get_by_id(:sell, trade.order_id)

      if order_buy && order_sell
        logger.error "ID:#{id} one order made a trade ?! order id:#{trade.order_id}"
        return
      end
      order_back(trade, order_buy) if order_buy
      order_back(trade, order_sell) if order_sell
    end

    def order_back(trade, order)
      logger.info("ID:#{id} Trade on #{trade.market}, #{order.side} price: #{trade.price} amount: #{trade.volume}")
      spread = order.side == :sell ? @spread_asks : @spread_bids
      price = remove_spread(order.side, trade.price, spread)
      type = order.side == :sell ? :buy : :sell

      logger.info("ID:#{id} Buffering order back #{trade.market}, #{type} price: #{price} amount: #{trade.volume}")
      @trades[trade.id] ||= {}
      @trades[trade.id][trade.order_id] = [trade.market, price, trade.volume, type]

      @timer ||= EM::Synchrony.add_timer(@orderback_grace_time) do
        grouped_trades = group_trades(@trades)
        orders = []
        actions = []
        grouped_trades.each do |k, v|
          order = Arke::Order.new(target.id, k[0].to_f, v, k[1].to_sym)
          order.apply_requirements(source.account)
          if order.amount > @min_order_back_amount
            logger.info("ID:#{id} Pushing order back #{order} (min order back amount: #{@min_order_back_amount})")
            orders << order
          else
            logger.info("ID:#{id} Discard order back #{order} (min order back amount: #{@min_order_back_amount})")
          end
        end

        orders.each do |order|
          actions << Arke::Action.new(:order_create, source, order: order)
        end
        source.account.executor.push(actions)
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
      raise "Source order book is empty" if top_ask.nil? || top_bid.nil?

      price_points_asks = @side_asks ? split_constant_pp(:asks, top_ask.first, @levels_count, split_opts) : nil
      price_points_bids = @side_bids ? split_constant_pp(:bids, top_bid.first, @levels_count, split_opts) : nil
      ob_agg = source.orderbook.aggregate(
        price_points_bids,
        price_points_asks,
        target.min_amount
      )
      ob = ob_agg.to_ob

      limit_asks_quote = source.account.balance(source.quote)["free"]
      limit_bids_quote = target.account.balance(target.quote)["total"]

      source_base_free = source.account.balance(source.base)["free"]
      target_base_total = target.account.balance(target.base)["total"]

      if source_base_free < limit_bids_base
        limit_bids_base_applied = source_base_free
        logger.warn("#{source.base} balance on #{source.account.driver} is #{source_base_free} lower then the limit set to #{@limit_bids_base}")
      else
        limit_bids_base_applied = limit_bids_base
      end

      if target_base_total < limit_asks_base
        limit_asks_base_applied = target_base_total
        logger.warn("#{target.base} balance on #{target.account.driver} is #{target_base_total} lower then the limit set to #{@limit_asks_base}")
      else
        limit_asks_base_applied = limit_asks_base
      end

      ob_adjusted = ob.adjust_volume(
        limit_bids_base_applied,
        limit_asks_base_applied,
        limit_bids_quote,
        limit_asks_quote
      )
      ob_spread = ob_adjusted.spread(@spread_bids, @spread_asks)

      price_points_asks = price_points_asks&.map {|pp| ::Arke::PricePoint.new(apply_spread(:sell, pp.price_point, @spread_asks)) }
      price_points_bids = price_points_bids&.map {|pp| ::Arke::PricePoint.new(apply_spread(:buy, pp.price_point, @spread_bids)) }

      push_debug("0_asks_price_points", price_points_asks)
      push_debug("0_bids_price_points", price_points_bids)
      push_debug("1_ob_agg", ob_agg)
      push_debug("2_ob", "\n#{ob}")
      push_debug("3_ob_adjusted", "\n#{ob_adjusted}")
      push_debug("4_ob_spread", "\n#{ob_spread}")

      [ob_spread, {asks: price_points_asks, bids: price_points_bids}]
    end
  end
end
