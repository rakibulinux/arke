# encoding: UTF-8
# frozen_string_literal: true

def construct_orderbook(market, book)
  ob = Arke::Orderbook::Orderbook.new(market)
  ob.instance_variable_set(:@book, book)
  return ob
end
