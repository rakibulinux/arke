# frozen_string_literal: true

module Arke::Scheduler
  class Smart < Simple
    include ::Arke::Helpers::Orderbook

    def initialize(current_ob, desired_ob, target, opts={})
      super
      @price_levels = opts[:price_levels]
      @max_amount_per_order = opts[:max_amount_per_order]
      raise "price_levels are missing" unless @price_levels
    end

    def cancel_risky_orders(side, desired_best_price)
      actions = []
      @current_ob[side].each do |price, orders|
        orders.each do |id, order|
          if better(side, price, desired_best_price)
            priority = 1e9 + (price - desired_best_price).abs
            actions.push(::Arke::Action.new(:order_stop, @target, id: id, order: order, priority: priority))
          end
        end
      end
      actions
    end

    def current_amount(side, grouped_orders, level_index, desired_best_price)
      return 0.0 unless grouped_orders[level_index]

      grouped_orders[level_index][:orders].reject {|order|
        better(side, order.price, desired_best_price)
      }.sum(&:amount)
    end

    def adjust_levels(side, price_levels, desired_best_price)
      actions = []
      current = @current_ob.group_by_level(side, price_levels)
      desired = @desired_ob.group_by_level(side, price_levels)

      price_levels.each_with_index do |price_point, i|
        current_amount = current_amount(side, current, i, desired_best_price)
        desired_amount = desired[i][:orders].sum
        diff_amount = desired_amount - current_amount
        priority = 1e3 * (1 + 1 / (i.to_d + 1)) # Priority to first levels
        if diff_amount.negative?
          current[i][:orders].each do |order|
            diff_amount += order.amount.to_d
            actions.push(::Arke::Action.new(:order_stop, @target, order: order, priority: priority))
            next if diff_amount >= 0
          end
          next
        end

        next unless diff_amount.positive?

        while diff_amount.positive?
          amount = [diff_amount, @max_amount_per_order].min
          diff_amount -= amount
          order = ::Arke::Order.new(@market, price_point.weighted_price, amount, side)
          actions.push(::Arke::Action.new(:order_create, @target, order: order, priority: priority))
          next if diff_amount <= 0
        end
      end
      actions
    end

    def schedule
      list = []
      desired_best_sell = @desired_ob.best_price(:sell)
      desired_best_buy = @desired_ob.best_price(:buy)

      if !desired_best_buy.nil? && !desired_best_sell.nil? && desired_best_sell <= desired_best_buy
        raise InvalidOrderBook.new("Ask price < Bid price")
      end

      list += cancel_risky_orders(:sell, desired_best_sell)
      list += cancel_risky_orders(:buy, desired_best_buy)
      list += adjust_levels(:sell, @price_levels[:asks], desired_best_sell)
      list += adjust_levels(:buy,  @price_levels[:bids], desired_best_buy)

      list
    end
  end
end
