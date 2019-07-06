module Arke
  class Order

    attr_reader :market, :price, :side, :type
    attr_accessor :amount

    def initialize(market, price, amount, side, type = "limit")
      @market = market
      @price = price
      @amount = amount
      @side = side
      @type = type
    end

    def to_s
      "<Order #{market}:#{type}:#{side} price:#{price} amount:#{amount}>"
    end
    alias :inspect :to_s

    def ==(order)
      !order.nil? && \
      order.market == market && \
      order.price == price && \
      order.amount == amount && \
      order.side == side
    end
  end
end
