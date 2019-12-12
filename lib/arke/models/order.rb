# frozen_string_literal: true

module Arke
  class Order
    include Arke::Helpers::Precision

    attr_reader :market, :price, :side, :type
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

    def ==(order)
      !order.nil? && \
      order.market == market && \
      order.price == price && \
      order.amount == amount && \
      order.side == side
    end

    #
    # Apply market requirement to the orders
    #
    # - Price precision
    # - Amount precision
    # - Minimum amount
    #
    def apply_requirements(target_exchange)
      config = target_exchange.market_config(@market)
      @price = apply_precision(@price, config["price_precision"])
      @amount = apply_precision(@amount, config["amount_precision"], config["min_amount"])
    end
  end
end
