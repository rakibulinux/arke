# frozen_string_literal: true

module Arke::Orderbook
  class Orderbook < Base
    def new_price(price, volume)
      {
        volume:       volume.to_f,
        high_price:   price.to_f,
        low_price:    price.to_f,
        volume_price: volume.to_f * price,
      }
    end

    def group_by_price_points(side, price_points, minimum_volume)
      tree = ::RBTree.new
      volume_base = 0.0
      volume_quote = 0.0

      @book[side].each do |order_price, order_volume|
        while !price_points.empty? && better(side, price_points.first, order_price)
          price_point = price_points.first
          # Create an order with minimum volume if there is no order in range
          if tree[price_point].nil? || tree[price_point][:volume].to_f.zero?
            tree[price_point] = new_price(price_point, minimum_volume)
            volume_base += minimum_volume
            volume_quote += minimum_volume * price_point
          end
          price_points.shift
        end
        break if price_points.empty?

        price_point = price_points.first
        tree[price_point] ||= new_price(order_price, 0.0)
        volume_base += order_volume
        volume_quote += order_volume * order_price
        tree[price_point][:volume] += order_volume
        tree[price_point][:high_price] = order_price if order_price > tree[price_point][:high_price]
        tree[price_point][:low_price] = order_price if order_price < tree[price_point][:low_price]
        tree[price_point][:volume_price] += order_price * order_volume
      end
      [tree, volume_base, volume_quote]
    end

    def aggregate_side(side, price_points, minimum_volume=0.1)
      return [nil, nil, nil] if price_points.nil?

      tree, volume_base, volume_quote = group_by_price_points(side, price_points, minimum_volume)

      # Add remaining price points in case there is no more orders in the input
      price_points.each do |price_point|
        next if tree[price_point]

        tree[price_point] = new_price(price_point, minimum_volume)
        volume_base += minimum_volume
        volume_quote += minimum_volume * price_point
      end

      # Calculate weighted_price
      wtree = ::RBTree.new
      tree.each do |price_point, _data|
        wtree[price_point] = {
          volume:         tree[price_point][:volume],
          high_price:     tree[price_point][:high_price],
          low_price:      tree[price_point][:low_price],
          weighted_price: tree[price_point][:volume_price] / tree[price_point][:volume],
        }
      end

      final_tree = ::RBTree.new
      wtree.each do |_price_point, data|
        final_tree[data[:weighted_price]] = data
      end
      [final_tree, volume_base, volume_quote]
    end

    def aggregate(price_points_buy, price_points_sell, min_ask_amount, min_bid_amount)
      bids_ob, vol_bids_base, vol_bids_quote = aggregate_side(:buy, price_points_buy, min_bid_amount)
      asks_ob, vol_asks_base, vol_asks_quote = aggregate_side(:sell, price_points_sell, min_ask_amount)
      Aggregated.new(
        @market,
        buy:               bids_ob,
        sell:              asks_ob,
        volume_bids_quote: vol_bids_quote,
        volume_asks_quote: vol_asks_quote,
        volume_bids_base:  vol_bids_base,
        volume_asks_base:  vol_asks_base
      )
    end

    def adjust_volume(limit_bids_base, limit_asks_base, limit_bids_quote=nil, limit_asks_quote=nil)
      if limit_bids_base && (limit_bids_base < @volume_bids_base)
        volume_bids_base = 0.0
        volume_bids_quote = 0.0
        bids = ::RBTree.new
        do_break = false
        self[:buy].each do |price, amount|
          amount = (limit_bids_base * amount / @volume_bids_base)
          amount_quote = amount * price
          if limit_bids_quote && (volume_bids_quote + amount_quote > limit_bids_quote)
            amount_quote = limit_bids_quote - volume_bids_quote
            amount = amount_quote / price
            ::Arke::Log.warn "Bids volume throttled to #{amount} because of quote currency"
            do_break = true
          end
          bids[price] = amount
          volume_bids_base += amount
          volume_bids_quote += amount_quote
          break if do_break
        end
      else
        volume_bids_base = self.volume_bids_base
        volume_bids_quote = self.volume_bids_quote
        bids = self[:buy]
      end

      if limit_asks_base && (limit_asks_base < @volume_asks_base)
        volume_asks_base = 0.0
        volume_asks_quote = 0.0
        asks = ::RBTree.new
        do_break = false
        self[:sell].each do |price, amount|
          amount = (limit_asks_base * amount / @volume_asks_base)
          amount_quote = amount * price
          if limit_asks_quote && (volume_asks_quote + amount_quote > limit_asks_quote)
            amount_quote = limit_asks_quote - volume_asks_quote
            amount = amount_quote / price
            ::Arke::Log.warn "Asks volume throttled to #{amount} because of quote currency"
            do_break = true
          end
          asks[price] = amount
          volume_asks_base += amount
          volume_asks_quote += amount_quote
          break if do_break
        end
      else
        volume_asks_base = self.volume_asks_base
        volume_asks_quote = self.volume_asks_quote
        asks = self[:sell]
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

    def print(side=:buy)
      header = %w[Price Amount]
      rows = []
      @book[side].each do |price, amount|
        rows << ["%.6f" % price, "%.6f" % amount]
      end
      table = TTY::Table.new header, rows
      table.render(:ascii, padding: [0, 2], alignment: [:right])
    end

    def merge!(ob)
      @book.each do |k, _v|
        @book[k].merge!(ob[k]) {|_price, amount, ob_amount| amount + ob_amount }
      end
    end
  end
end
