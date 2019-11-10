# frozen_string_literal: true

module Arke::Orderbook
  class Base
    include ::Arke::Helpers::Orderbook

    attr_reader :book, :market
    attr_reader :volume_bids_quote, :volume_asks_quote

    def initialize(market, opts={})
      @market = market
      @book = {
        buy:  opts[:buy] || ::RBTree.new,
        sell: opts[:sell] || ::RBTree.new,
      }
      @book[:buy].readjust {|a, b| b <=> a }
      @volume_bids_base = opts[:volume_bids_base]
      @volume_asks_base = opts[:volume_asks_base]
      @volume_bids_quote = opts[:volume_bids_quote]
      @volume_asks_quote = opts[:volume_asks_quote]
    end

    def update(order)
      @book[order.side][order.price] = order.amount
    end

    def clone
      ob = Orderbook.new(@market)
      ob.merge!(self)
      ob
    end

    def delete(order)
      @book[order.side].delete(order.price)
    end

    def contains?(order)
      !@book[order.side][order.price].nil?
    end

    # get with the best price
    def get(side)
      @book[side].first
    end

    def last(side)
      @book[side].last
    end

    def best_price(side)
      get(side)&.first
    end

    def stats(side)
      price_range = (last(side).first - best_price(side)).abs
      volume = side == :buy ? volume_bids_base : volume_asks_base

      {
        price_range: price_range,
        volume:      volume,
      }
    end

    def volume_bids_base
      @volume_bids_base ||= @book[:buy].inject(0.0) {|sum, n| sum + n.last }
    end

    def volume_asks_base
      @volume_asks_base ||= @book[:sell].inject(0.0) {|sum, n| sum + n.last }
    end

    def [](side)
      @book[side]
    end

    def spread(bids_spread, asks_spread)
      asks_spread = 1 + asks_spread
      bids_spread = 1 - bids_spread
      bids = ::RBTree.new
      asks = ::RBTree.new
      volume_bids_quote = 0.0
      volume_asks_quote = 0.0

      self[:buy].each do |k, v|
        price = (BigDecimal(k) * bids_spread).round(16)
        bids[price] = v.round(16)
        volume_bids_quote += price * v
      end
      self[:sell].each do |k, v|
        price = (BigDecimal(k) * asks_spread).round(16)
        asks[price] = v.round(16)
        volume_asks_quote += price * v
      end

      self.class.new(
        @market,
        buy:               bids,
        sell:              asks,
        volume_bids_quote: volume_bids_quote,
        volume_asks_quote: volume_asks_quote,
        volume_bids_base:  volume_bids_base,
        volume_asks_base:  volume_asks_base
      )
    end

    def group_by_level(side, price_points)
      result = []
      level_index = 0
      init_level = proc do |price_point|
        {
          price:  price_point,
          orders: []
        }
      end

      @book[side].each do |order_price, data|
        while level_index < price_points.size && better(side, price_points[level_index].price_point, order_price)
          level_index += 1
          price_point = price_points[level_index].price_point
          result[level_index] = init_level.call(price_point)
        end
        break if level_index >= price_points.size

        price_point = price_points[level_index].price_point
        result[level_index] ||= init_level.call(price_point)

        case self
        when OpenOrders
          result[level_index][:orders] += data.values
        else
          result[level_index][:orders] << data
        end
      end
      result
    end

    def indent(line, indentation)
      " " * indentation + line
    end

    def to_s_side(side, indentation=0)
      chunks = []
      self[side].each do |price, data|
        chunks << indent("%-05.8f       %s" % [price, data.inspect], indentation)
      end
      chunks.join("\n")
    end

    def to_s(indentation=0)
      [
        indent("asks", indentation),
        to_s_side(:sell, indentation + 2),
        indent("bids", indentation),
        to_s_side(:buy, indentation + 2),
      ].join("\n")
    end
  end
end
