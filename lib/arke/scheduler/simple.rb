# frozen_string_literal: true

module Arke::Scheduler
  class InvalidOrderBook < StandardError; end

  class Simple
    include ::Arke::Helpers::Precision
    attr_accessor :actions
    attr_reader :logger

    def initialize(current_ob, desired_ob, target, opts={})
      @logger = Arke::Log
      @opts = opts
      @current_ob = current_ob
      @desired_ob = desired_ob
      @target = target
      @market = current_ob.market
      @actions = []
    end

    def desired_contains?(book, price, amount)
      !book[price].nil? && book[price].values.map(&:amount).sum == amount
    end

    def current_contains?(book, price, amount)
      !book[price].nil? && book[price] == amount
    end

    def sort_cancel_create_weaved_by_amount(list, side)
      actions_stop = list.select {|a| a.type == :order_stop && a.params[:order].side == side }
      actions_create = list.select {|a| a.type == :order_create && a.params[:order].side == side }
      output = []
      free_amount = 0.0
      while !actions_stop.empty? || !actions_create.empty?
        if actions_stop.empty?
          free_amount = nil
        else
          action = actions_stop.shift
          free_amount += action.params[:order].amount
          output << action
        end

        while !actions_create.empty? && \
          (free_amount.nil? || actions_create.first.params[:order].amount <= free_amount)
          action = actions_create.shift
          free_amount -= action.params[:order].amount unless free_amount.nil?
          output << action
        end
      end
      output
    end

    def schedule
      list = []
      desired_best_sell = @desired_ob.best_price(:sell)
      desired_best_buy = @desired_ob.best_price(:buy)
      current_best_sell = @current_ob.best_price(:sell)

      if !desired_best_buy.nil? && !desired_best_sell.nil? && desired_best_sell <= desired_best_buy
        raise InvalidOrderBook.new("Ask price < Bid price")
      end

      # stop orders
      %i[buy sell].each do |side|
        current = @current_ob[side]

        current.each do |_price, orders|
          orders.each do |id, order|
            list.push(::Arke::Action.new(:order_stop, @target, id: id, order: order))
          end
        end
      end

      # create orders
      %i[buy sell].each do |side|
        desired = @desired_ob[side]

        desired.each do |price, amount|
          price = apply_precision(price, @target.price_precision)
          amount = apply_precision(amount, @target.amount_precision, side == :sell ? @target.min_amount : @target.min_amount)
          if price.positive? && amount.positive?
            list.push(::Arke::Action.new(:order_create, @target, order: ::Arke::Order.new(@market, price, amount, side)))
          end
        end
      end

      if desired_best_buy.nil? || current_best_sell.nil? || desired_best_buy >= current_best_sell
        @actions += sort_cancel_create_weaved_by_amount(list, :sell)
        @actions += sort_cancel_create_weaved_by_amount(list, :buy)
      else
        @actions += sort_cancel_create_weaved_by_amount(list, :buy)
        @actions += sort_cancel_create_weaved_by_amount(list, :sell)
      end
      @actions
    end
  end
end
