# frozen_string_literal: true

module Arke::Scheduler
  class Smart < Simple
    include ::Arke::Helpers::Orderbook

    HIGH_LIQUIDITY_IN_ORDERBOOK = 1.20
    LOW_LIQUIDITY_IN_ORDERBOOK = 0.80
    ADJUST_LEVEL_AMOUNT_RATIO = 0.80

    attr_reader :limit_asks_base
    attr_reader :limit_bids_base
    attr_reader :limit_bids_quote

    def initialize(current_ob, desired_ob, target, opts={})
      super

      @price_levels = opts[:price_levels]
      @max_amount_per_order = opts[:max_amount_per_order]&.to_d
      @limit_asks_base = opts[:limit_asks_base]&.to_d
      @limit_bids_base = opts[:limit_bids_base]&.to_d
      @limit_bids_quote = opts[:limit_bids_quote]&.to_d
      @fast_track_liquidity_asks = 0.0
      @fast_track_liquidity_bids = 0.0
      raise "price_levels are missing" unless @price_levels
    end

    #
    #  Scheduler tracks priorities
    #
    # - orders at risk:               10^6 - price distance from the best price
    # - orders out boundaries:        10^6 - price distance from the best price (when low liquidity flag is raised)
    # - create orders in boundaries:  10^6 - price distance from the best price (when low levels flags is raised)
    # - orders in boundaries:         10^3 - price distance from the best price
    # - orders out boundaries:        1    - price distance from the best price
    #
    PRIORITY_PRECISION = 6

    def track_super_fast(constant=0)
      (1e9 + constant).round(PRIORITY_PRECISION)
    end

    def track_fast(constant=0)
      (1e6 + constant).round(PRIORITY_PRECISION)
    end

    def track_normal(constant=0)
      (1e3 + constant).round(PRIORITY_PRECISION)
    end

    def track_low(constant=0)
      (1 + constant).round(PRIORITY_PRECISION)
    end

    def fast_track_liquidity_accounting(action)
      raise "Wrong action type for accounting: #{action.type}" unless %i[order_create order_stop].include?(action.type)

      factor = action.type == :order_create ? +1 : -1
      order = action.params[:order]

      case order.side.to_s
      when "buy"
        @fast_track_liquidity_bids += order.amount * factor
      when "sell"
        @fast_track_liquidity_asks += order.amount * factor
      else
        raise "Wrong order side #{order.side}"
      end
    end

    def cancel_risky_orders(side, desired_best_price)
      return [] if desired_best_price.nil?

      actions = []
      @current_ob[side].each do |price, orders|
        orders.each do |_id, order|
          next unless better(side, price, desired_best_price)

          priority = track_super_fast((price - desired_best_price).abs)
          action = ::Arke::Action.new(:order_stop, @target, order: order, priority: priority)
          fast_track_liquidity_accounting(action)
          actions.push(action)
        end
      end
      actions
    end

    def cancel_out_of_boundaries_orders(side, last_level_price, &high_liquidity)
      return [] if last_level_price.nil?

      actions = []
      @current_ob[side].each do |price, orders|
        orders.each do |_id, order|
          next unless better(side, last_level_price, price)
          logger.warn { "High liquidity flag raised on side #{side}" } if high_liquidity.call()

          priority = (price - last_level_price).abs
          priority = high_liquidity.call() ? track_fast(priority) : track_low(priority)
          action = ::Arke::Action.new(:order_stop, @target, order: order, priority: priority)
          fast_track_liquidity_accounting(action) if high_liquidity.call()
          actions.push(action)
        end
      end
      actions
    end

    def current_amount(side, grouped_orders, level_index, desired_best_price)
      return 0.0 unless grouped_orders[level_index]

      grouped_orders[level_index][:orders].reject {|order|
        !desired_best_price.nil? && better(side, order.price, desired_best_price)
      }.sum(&:amount)
    end

    def prefix
      "ID:#{@target&.id}"
    end

    def adjust_levels(side, price_levels, desired_best_price, &low_liquidity)
      actions = []
      current = @current_ob.group_by_level(side, price_levels)
      desired = @desired_ob.group_by_level(side, price_levels)
      logger.debug { "#{prefix} #{side} price_levels: #{price_levels.inspect}" }
      logger.debug { "#{prefix} #{side} current: #{current.inspect}" }
      logger.debug { "#{prefix} #{side} desired: #{desired.inspect}" }

      price_levels.each_with_index do |price_point, i|
        raise "PricePoint expected, got #{price_point.class}" unless price_point.is_a?(::Arke::PricePoint)

        current_amount = current_amount(side, current, i, desired_best_price)
        desired_amount = desired[i] ? desired[i][:orders].sum : 0
        diff_amount = desired_amount - current_amount
        diff_percent = desired_amount.zero? ? 1000 : diff_amount.abs.to_d / desired_amount.to_d

        if diff_percent <= ADJUST_LEVEL_AMOUNT_RATIO
          logger.info { "#{prefix} L%02.0f #{side} wants:%0.6f now:%0.6f diff:%0.0f%% (SKIPPED)" % [i + 1, desired_amount, current_amount, diff_percent * 100] }
          next
        else
          logger.info { "#{prefix} L%02.0f #{side} wants:%0.6f now:%0.6f diff:%0.0f%%" % [i + 1, desired_amount, current_amount, diff_percent * 100] }
        end

        # CANCEL ORDERS
        if diff_amount.negative?
          current[i][:orders].sort_by(&:amount).each do |order|
            diff_amount += order.amount.to_d
            priority = 100.to_d / (1.to_d + (desired_best_price.to_d - order.price).abs)
            priority = track_normal(priority)
            actions.push(::Arke::Action.new(:order_stop, @target, order: order, priority: priority))
            break if diff_amount >= 0
          end
          next
        end

        logger.warn { "#{prefix} Low liquidity flag raised on side #{side}" } if low_liquidity.call()

        # CREATE ORDERS
        while diff_amount.positive?
          amount = @max_amount_per_order ? [diff_amount, @max_amount_per_order].min : diff_amount
          price = price_point.weighted_price || desired[i][:price]
          priority = 100.to_d / (1.to_d + (desired_best_price - price).abs)
          priority = low_liquidity.call() ? track_fast(priority) : track_normal(priority)
          diff_amount -= amount
          order = ::Arke::Order.new(@market, price, amount, side)
          action = ::Arke::Action.new(:order_create, @target, order: order, priority: priority)
          fast_track_liquidity_accounting(action) if low_liquidity.call()
          actions.push(action)
          break if diff_amount <= 0
        end
      end
      actions
    end

    def liquidity_sell
      @liquidity_sell ||= @current_ob.total_side_amount(:sell)
      @liquidity_sell + @fast_track_liquidity_asks
    end

    def liquidity_buy
      @liquidity_buy ||= @current_ob.total_side_amount(:buy)
      @liquidity_buy + @fast_track_liquidity_bids
    end

    def liquidity_buy_quote
      @liquidity_buy_quote ||= @current_ob.total_side_amount_in_quote(:buy)
    end

    def high_liquidity_buy_flag
      return true if limit_bids_quote && liquidity_buy_quote > limit_bids_quote * HIGH_LIQUIDITY_IN_ORDERBOOK
      return true if limit_bids_base && liquidity_buy > limit_bids_base * HIGH_LIQUIDITY_IN_ORDERBOOK

      false
    end

    def high_liquidity_sell_flag
      return true if limit_asks_base && liquidity_sell > limit_asks_base * HIGH_LIQUIDITY_IN_ORDERBOOK

      false
    end

    def low_liquidity_buy_flag
      return true if limit_bids_quote && liquidity_buy_quote < limit_bids_quote * LOW_LIQUIDITY_IN_ORDERBOOK
      return true if limit_bids_base && liquidity_buy < limit_bids_base * LOW_LIQUIDITY_IN_ORDERBOOK

      false
    end

    def low_liquidity_sell_flag
      return true if limit_asks_base && liquidity_sell < limit_asks_base * LOW_LIQUIDITY_IN_ORDERBOOK

      false
    end

    def schedule
      desired_best_sell = @desired_ob.best_price(:sell)
      desired_best_buy = @desired_ob.best_price(:buy)

      logger.debug { "#{prefix} SmartScheduler: desired_best_sell #{desired_best_sell}" }
      logger.debug { "#{prefix} SmartScheduler: desired_best_buy  #{desired_best_buy}" }

      if !desired_best_buy.nil? && !desired_best_sell.nil? && desired_best_sell <= desired_best_buy
        raise InvalidOrderBook.new("#{prefix} Ask price < Bid price")
      end

      list = []
      list += cancel_risky_orders(:sell, desired_best_sell)
      list += cancel_risky_orders(:buy, desired_best_buy)
      list += adjust_levels(:sell, @price_levels[:asks], desired_best_sell, &proc { low_liquidity_sell_flag })
      list += adjust_levels(:buy,  @price_levels[:bids], desired_best_buy, &proc { low_liquidity_buy_flag })
      list += cancel_out_of_boundaries_orders(:buy,  @price_levels[:bids].last&.price_point, &proc { high_liquidity_buy_flag })
      list += cancel_out_of_boundaries_orders(:sell, @price_levels[:asks].last&.price_point, &proc { high_liquidity_sell_flag })
      list = list.sort_by(&:priority).reverse
      logger.warn { "#{prefix} SmartScheduler: accounting fast track bids: #{@fast_track_liquidity_bids}" }
      logger.warn { "#{prefix} SmartScheduler: accounting fast track asks: #{@fast_track_liquidity_asks}" }
      logger.debug { "#{prefix} SmartScheduler: returned actions: #{list}" }
      list
    end
  end
end
