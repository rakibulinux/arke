# frozen_string_literal: true

module Arke
  class Order
    include Arke::Helpers::Precision

    attr_reader :market, :price, :side, :type, :price_s, :amount_s
    attr_accessor :amount, :id

    def initialize(market, price, amount, side, type="limit", id=nil)
      @market = market
      @price = price.to_d
      @amount = amount.to_d
      @side = side
      @type = type
      @id = id
    end

    def to_s
      id_s = id ? "id:#{id} " : ""
      "<Order #{id_s}#{market}:#{type}:#{side} price:#{price} amount:#{amount}>"
    end
    alias inspect to_s

    def to_h
      {
        "market" => @market.to_s,
        "price" => @price.to_s,
        "amount" => @amount.to_s,
        "side" => @side.to_s,
        "type" => @type.to_s,
        "id" => @id.to_s,
      }
    end

    def ==(order)
      !order.nil? && \
      order.market == market && \
      order.price == price && \
      order.amount == amount && \
      order.side == side && \
      order.type.to_s == type.to_s
    end

    #
    # Apply market requirement to the orders
    #
    # - Price precision
    # - Amount precision
    # - Minimum amount
    #
    def apply_requirements(target_exchange)
      market_config = target_exchange.market_config(@market)
      price_precision = market_config["price_precision"]
      amount_precision = market_config["amount_precision"]
      min_amount = market_config["min_amount"]
      min_order_size = market_config["min_order_size"]
      amount_rounding_method = :floor

      if !min_order_size.nil? && @price.to_d.positive?
        size = @price * @amount
        if size < min_order_size
          min_amount = @amount = min_order_size / @price
          amount_rounding_method = :ceil
        end
      end

      @price = apply_precision(@price, price_precision)
      @amount = apply_precision(@amount, amount_precision, min_amount, amount_rounding_method)
      @price_s = "%0.#{price_precision.to_i}f" % @price
      @amount_s = "%0.#{amount_precision.to_i}f" % @amount
    end
  end
end
