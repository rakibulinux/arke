module Arke::Orderbook
  class Orderbook < Base

    def aggregate_side(side, price_points)
      return [nil, nil, nil] if price_points.nil?
      price_points = price_points.clone
      tree = ::RBTree.new
      volume_base, volume_quote, price_shift = 0.0, 0.0, 0.0
      @book[side].each do |order_price, order_volume|

        while better(side, price_points.first + price_shift, order_price) do
          price_point = price_points.first
          if tree[price_point].nil? or tree[price_point][:volume].to_f == 0
            # No order in the step, we will shift next price points to keep the expected steps count
            price_shift = order_price - price_point
          else
            if price_point and tree[price_point]
              tree[price_point][:weighted_price] = tree[price_point][:volume_price] / tree[price_point][:volume]
              tree[price_point].delete(:volume_price)
            end
            price_points.shift
            break if price_points.size == 0
          end
        end

        break if price_points.size == 0
        price_point = price_points.first
        tree[price_point] ||= {
          volume: 0,
          high_price: order_price,
          low_price: order_price,
          volume_price: 0.0,
        }
        volume_base += order_volume
        volume_quote += order_volume * order_price
        tree[price_point][:volume] += order_volume
        tree[price_point][:high_price] = order_price if order_price > tree[price_point][:high_price]
        tree[price_point][:low_price] = order_price if order_price < tree[price_point][:low_price]
        tree[price_point][:volume_price] += order_price * order_volume
      end

      if (price_point = price_points.first) and tree[price_point]
        tree[price_point][:weighted_price] = tree[price_point][:volume_price] / tree[price_point][:volume]
        tree[price_point].delete(:volume_price)
      end

      final_tree = ::RBTree.new
      tree.each do |price_point, data|
        final_tree[data[:weighted_price]] = data
      end
      return [final_tree, volume_base, volume_quote]
    end

    def aggregate(price_points_buy, price_points_sell)
      bids_aggregated_orderbook, volume_bids_base, volume_bids_quote = aggregate_side(:buy, price_points_buy)
      asks_aggregated_orderbook, volume_asks_base, volume_asks_quote = aggregate_side(:sell, price_points_sell)
      Aggregated.new(
        @market,
        buy: bids_aggregated_orderbook,
        sell: asks_aggregated_orderbook,
        volume_bids_quote: volume_bids_quote,
        volume_asks_quote: volume_asks_quote,
        volume_bids_base: volume_bids_base,
        volume_asks_base: volume_asks_base,
      )
    end

    def adjust_volume(limit_bids_base, limit_asks_base, limit_bids_quote = nil, limit_asks_quote = nil)
      if limit_bids_base and limit_bids_base < @volume_bids_base
        volume_bids_base, volume_bids_quote, bids = 0.0, 0.0, ::RBTree.new
        do_break = false
        self[:buy].each do |price, amount|
          amount = (limit_bids_base * amount / @volume_bids_base)
          amount_quote = amount * price
          if limit_bids_quote and volume_bids_quote + amount_quote > limit_bids_quote
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
        volume_bids_base, volume_bids_quote, bids = self.volume_bids_base, self.volume_bids_quote, self[:buy]
      end

      if limit_asks_base and limit_asks_base < @volume_asks_base
        volume_asks_base, volume_asks_quote, asks = 0.0, 0.0, ::RBTree.new
        do_break = false
        self[:sell].each do |price, amount|
          amount = (limit_asks_base * amount / @volume_asks_base)
          amount_quote = amount * price
          if limit_asks_quote and volume_asks_quote + amount_quote > limit_asks_quote
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
        volume_asks_base, volume_asks_quote, asks = self.volume_asks_base, self.volume_asks_quote, self[:sell]
      end

      Orderbook.new(
        @market,
        buy: bids,
        sell: asks,
        volume_bids_quote: volume_bids_quote,
        volume_asks_quote: volume_asks_quote,
        volume_bids_base: volume_bids_base,
        volume_asks_base: volume_asks_base,
      )
    end

    def print(side = :buy)
      header = ['Price', 'Amount']
      rows = []
      @book[side].each do |price, amount|
        rows << ['%.6f' % price, '%.6f' % amount]
      end
      table = TTY::Table.new header, rows
      table.render(:ascii, padding: [0, 2], alignment: [:right])
    end

    def merge!(ob)
      @book.each do |k, _v|
        @book[k].merge!(ob[k]) { |_price, amount, ob_amount| amount + ob_amount }
      end
    end
  end
end
