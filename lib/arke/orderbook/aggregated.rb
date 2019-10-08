# frozen_string_literal: true

module Arke::Orderbook
  class Aggregated < Base
    def to_ob
      asks = ::RBTree.new
      bids = ::RBTree.new
      volume_bids_base = 0
      volume_asks_base = 0
      volume_bids_quote = 0
      volume_asks_quote = 0

      self[:buy].each do |price, data|
        order = Arke::Order.new(@market, price, data[:volume], :buy)
        bids[order.price] = order.amount
        volume_bids_base += order.amount
        volume_bids_quote += order.amount * order.price
      end

      self[:sell].each do |price, data|
        order = Arke::Order.new(@market, price, data[:volume], :sell)
        asks[order.price] = order.amount
        volume_asks_base += order.amount
        volume_asks_quote += order.amount * order.price
      end

      Orderbook.new(
        @market,
        buy:               bids,
        sell:              asks,
        volume_bids_quote: volume_bids_quote,
        volume_asks_quote: volume_asks_quote,
        volume_bids_base:  volume_bids_base,
        volume_asks_base:  volume_asks_base
      )
    end
  end
end
