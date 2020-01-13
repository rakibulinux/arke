# frozen_string_literal: true

module Arke::Strategy
  # * create random market orders
  # * the order amount is randomly from the min amount of the market to 2 times the min amount
  class Microtrades < Base
    include ::Arke::Helpers::Precision
    include ::Arke::Helpers::Spread
    class EmptyOrderBook < StandardError; end

    SIDES_MAP = {"asks" => :sell, "bids" => :buy, "both" => "both"}.freeze

    def initialize(sources, target, config, reactor)
      super
      params = @config["params"] || {}
      @min_amount = (params["min_amount"].to_d || target.min_amount)
      @max_amount = (params["max_amount"].to_d || @min_amount * 2).to_f
      @min_price = params["min_price"].to_d
      @max_price = params["max_price"].to_d
      @price_difference = params["price_difference"].to_d || 0.02 if linked_strategy_id
      @enable_orderback = false
      @sides = SIDES_MAP[@side]
      check_config
      logger.info "ID:#{id} Min amount: #{@min_amount}"
      logger.info "ID:#{id} Max amount: #{@max_amount}"
    end

    def check_config
      raise "ID:#{id} min_amount must be bigger than zero" unless @min_amount.positive?
      raise "ID:#{id} max_amount must be bigger than zero" unless @max_amount.positive?
      raise "ID:#{id} min_amount should be lower than max_amount" if @min_amount > @max_amount
    end

    def delay_the_first_execute
      true
    end

    def target_min_amount(market_infos)
      [
        market_infos["min_amount"],
        market_infos["min_amount"],
        target.min_amount,
        target.min_amount,
      ].map(&:to_f).reject(&:zero?).min
    end

    def get_amount(side)
      side_min_value = side == :sell ? target.min_amount.to_f : target.min_amount.to_f
      amount = rand(@min_amount.to_f..@max_amount.to_f)
      if @linked_strategy_id
        linked_target = @reactor.find_strategy(@linked_strategy_id).target
        side = side == :sell ? :buy : :sell
        side_amount = linked_target.open_orders.total_side_amount(side)
        amount = (side_amount * 0.6) > amount ? amount : (side_amount * 0.6)
      end
      apply_precision(amount, target.amount_precision.to_f, side_min_value)
    end

    def get_price(side)
      if @linked_strategy_id
        linked_target = @reactor.find_strategy(@linked_strategy_id).target
        top_ask = linked_target.open_orders[:sell].first
        top_bid = linked_target.open_orders[:buy].first
        if [top_ask, top_bid].include?(nil)
          raise EmptyOrderBook.new("Linked strategy orderbook is empty (top_ask:#{top_ask.inspect} top_bid: #{top_bid.inspect})")
        end

        price = side == :buy ? top_ask.first : top_bid.first
        # FIXME: use absolute value
        price = apply_spread(side, price, @price_difference * -1)
      else
        price = side == :buy ? @max_price : @min_price
      end
      price
    end

    def call
      Fiber.new do
        side = @sides == "both" ? %i[buy sell].sample : @sides
        order = Arke::Order.new(target.id, get_price(side), get_amount(side), side)
        order.apply_requirements(target.account)
        logger.warn "ID:#{id} Creating order #{order}"
        order = target.account.create_order(order)
        logger.warn "ID:#{id} Created order #{order}"
        EM::Synchrony.sleep(0.1)
        target.account.stop_order(order)
      rescue StandardError => e
        logger.error "ID:#{id} #{e}"
        logger.error e.backtrace.join("\n").to_s
      end.resume
      [nil, nil]
    end
  end
end
