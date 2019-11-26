# frozen_string_literal: true

module Arke::Scheduler
  class Smart < Simple
    include ::Arke::Helpers::Orderbook

    LOW_LIQUIDITY_RATIO = 1.20

    attr_reader :limit_asks_base
    attr_reader :limit_bids_base
    attr_reader :limit_bids_quote

    def initialize(current_ob, desired_ob, target, opts={})
      super

      @price_levels = opts[:price_levels]
      @max_amount_per_order = opts[:max_amount_per_order]
      @limit_asks_base = opts[:limit_asks_base]&.to_d
      @limit_bids_base = opts[:limit_bids_base]&.to_d
      @limit_bids_quote = opts[:limit_bids_quote]&.to_d
      raise "price_levels are missing" unless @price_levels
    end

    def cancel_risky_orders(side, desired_best_price)
      return [] if desired_best_price.nil?

      actions = []
      @current_ob[side].each do |price, orders|
        orders.each do |_id, order|
          if better(side, price, desired_best_price)
            priority = 1e9 + (price - desired_best_price).abs
            actions.push(::Arke::Action.new(:order_stop, @target, order: order, priority: priority))
          end
        end
      end
      actions
    end

    def cancel_out_of_boundaries_orders(side, last_level_price, low_liquidity=false)
      return [] if last_level_price.nil?

      logger.info { "Low liquidity flag raised" } if low_liquidity
      actions = []
      @current_ob[side].each do |price, orders|
        orders.each do |_id, order|
          if better(side, last_level_price, price)
            priority = (low_liquidity ? 1e6 : 1).to_d + (price - last_level_price).abs
            actions.push(::Arke::Action.new(:order_stop, @target, order: order, priority: priority))
          end
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

    def adjust_levels(side, price_levels, desired_best_price)
      actions = []
      current = @current_ob.group_by_level(side, price_levels)
      desired = @desired_ob.group_by_level(side, price_levels)

      logger.debug { "#{side} price_levels: #{price_levels.inspect}" }
      logger.debug { "#{side} current: #{current.inspect}" }
      logger.debug { "#{side} desired: #{desired.inspect}" }
      levels_count = price_levels.count.to_d
      price_levels.each_with_index do |price_point, i|
        raise "PricePoint expected, got #{price_point.class}" unless price_point.is_a?(::Arke::PricePoint)

        current_amount = current_amount(side, current, i, desired_best_price)
        desired_amount = desired[i] ? desired[i][:orders].sum : 0
        diff_amount = desired_amount - current_amount

        level_bonus = 1e3.to_d * (levels_count - i + 1) / levels_count # Priority to first levels
        liquidity_factor = 1e3.to_d * (desired_amount.zero? ? 1 : diff_amount / desired_amount).abs # Priority to liquidity change
        level_priority = (level_bonus + liquidity_factor).round(2)

        if diff_amount.negative?
          current[i][:orders].sort_by(&:amount).each do |order|
            diff_amount += order.amount.to_d
            priority = level_priority + 100.to_d / (1 + order.amount.to_d) # Cancel small amounts first to avoid fragmentation
            actions.push(::Arke::Action.new(:order_stop, @target, order: order, priority: priority))
            break if diff_amount >= 0
          end
          next
        end

        while diff_amount.positive?
          amount = @max_amount_per_order ? [diff_amount, @max_amount_per_order].min : diff_amount
          price = price_point.weighted_price || desired[i][:price]
          diff_amount -= amount
          order = ::Arke::Order.new(@market, price, amount, side)
          actions.push(::Arke::Action.new(:order_create, @target, order: order, priority: level_priority))
          break if diff_amount <= 0
        end
      end
      actions
    end

    def liquidity_flag_buy
      if limit_bids_quote
        liquidity_buy = @current_ob.total_side_amount_in_base(:buy)
        return true if liquidity_buy > limit_bids_quote * LOW_LIQUIDITY_RATIO
      end

      if limit_bids_base
        liquidity_buy = @current_ob.total_side_amount(:buy)
        return true if liquidity_buy > limit_bids_base * LOW_LIQUIDITY_RATIO
      end
      false
    end

    def liquidity_flag_sell
      if limit_asks_base
        liquidity_sell = @current_ob.total_side_amount(:sell)
        return true if liquidity_sell > limit_asks_base * LOW_LIQUIDITY_RATIO
      end
      false
    end

    def schedule
      desired_best_sell = @desired_ob.best_price(:sell)
      desired_best_buy = @desired_ob.best_price(:buy)

      logger.debug { "SmartScheduler: desired_best_sell #{desired_best_sell}" }
      logger.debug { "SmartScheduler: desired_best_buy  #{desired_best_buy}" }

      if !desired_best_buy.nil? && !desired_best_sell.nil? && desired_best_sell <= desired_best_buy
        raise InvalidOrderBook.new("Ask price < Bid price")
      end

      list = []
      list += cancel_risky_orders(:sell, desired_best_sell)
      list += cancel_risky_orders(:buy, desired_best_buy)
      list += adjust_levels(:sell, @price_levels[:asks], desired_best_sell)
      list += adjust_levels(:buy,  @price_levels[:bids], desired_best_buy)
      list += cancel_out_of_boundaries_orders(:buy,  @price_levels[:bids].last&.price_point, liquidity_flag_buy)
      list += cancel_out_of_boundaries_orders(:sell, @price_levels[:asks].last&.price_point, liquidity_flag_sell)
      list = list.sort_by(&:priority).reverse
      logger.debug { "SmartScheduler: returned actions: #{list}" }
      list
    end
  end
end
