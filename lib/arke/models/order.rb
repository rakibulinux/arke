# frozen_string_literal: true

module Arke
  class Order
    attr_reader :market, :price, :side, :type
    attr_accessor :amount, :id

    def initialize(market, price, amount, side, type="limit", id=nil)
      @market = market
      @price = price
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
  end
end
