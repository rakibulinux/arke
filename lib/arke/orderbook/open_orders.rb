module Arke::Orderbook
  class OpenOrders < Base
    def price_level(side, price)
      @book[side][price]
    end

    def exist?(side, price, id)
      @book[side][price] && @book[side][price][id] ? true : false
    end

    def clear
      [:buy, :sell].each do |side|
        @book[side].values.each { |h| h.keys.each { |id| remove_order(id)} }
      end
    end

    def contains?(side, price)
      !(@book[side][price].nil? || @book[side][price].empty?)
    end

    def get_by_id(side, order_id)
      @book[side].find{ |price, id| return id[order_id] }
    end

    def price_amount(side, price)
      @book[side][price].sum { |_id, order| order.amount }
    end

    def add_order(order)
      raise "Order id is nil" if order.id.nil?
      @book[order.side][order.price] ||= {}
      @book[order.side][order.price][order.id] = order
    end

    def update(order)
      raise "update disabled for OpenOrders"
    end

    def total_side_amount(side)
      amount = 0.to_d
      @book[side].each_value do |o|
        amount += o.values.sum(&:amount)
      end
      amount
    end

    def total_side_amount_in_base(side)
      amount = 0.to_d
      @book[side].each_value do |o|
        amount += o.values.sum(&:amount) * o.values.first.price
      end
      amount
    end

    def remove_order(id)
      cleanup = []
      @book[:sell].each { |k, v| v.delete(id); cleanup << [:sell, k] if v.empty? }
      @book[:buy].each { |k, v| v.delete(id); cleanup << [:buy, k] if v.empty? }
      cleanup.each { |side, price| @book[side].delete(price) }
    end

    def get_diff(orderbook, precision)
      diff = {
        create: { buy: [], sell: [] },
        delete: { buy: [], sell: [] },
        update: { buy: [], sell: [] },
      }

      [:buy, :sell].each do |side|
        our = @book[side]
        their = orderbook.book[side]

        their.each do |price, amount|
          if amount.floor(precision) > 0.0
            if !contains?(side, price)
              diff[:create][side].push(Arke::Order.new(@market, price, amount, side))
            else
              our_amount = price_amount(side, price)
              # creating additioanl order to adjust volume
              if our_amount != amount
                diff[:update][side].push(Arke::Order.new(@market, price, amount - our_amount, side))
              end
            end
          end
        end

        our.each do |_price, hash|
          hash.each do |id, order|
            diff[:delete][side].push(id) unless orderbook.contains?(order)
          end
        end
      end

      diff
    end

    def to_s_side(side, indentation = 0)
      chunks = []
      self[side].each do |price, orders|
        chunks << indent("%-05.5f       %-5.5f (ids: %s)" % [
          price,
          orders.sum { |id, order| order.amount },
          orders.map { |id, order| id }
        ],
        indentation)
      end
      chunks.join("\n")
    end
  end
end
