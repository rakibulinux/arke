# frozen_string_literal: true

module Arke::Orderbook
  class Generator
    def generate(opts={})
      @levels_count = opts[:levels_count]
      @levels_price_step = opts[:levels_price_step]
      @levels = opts[:levels]
      @random = opts[:random] || 0.0
      @market = opts[:market]
      @best_ask_price = opts[:best_ask_price]
      @best_bid_price = opts[:best_bid_price]
      @levels_price_func = opts[:levels_price_func] || "constant"
      shape = opts[:shape]&.downcase&.to_s || "w"
      raise "levels_count missing" unless @levels_count
      raise "best_ask_price missing" unless @best_ask_price
      raise "best_bid_price missing" unless @best_bid_price
      raise "levels_price_step missing" unless @levels_price_step
      raise "market missing" unless @market
      raise "best_bid_price > best_ask_price" if @best_bid_price > @best_ask_price

      @asks = ::RBTree.new
      @bids = ::RBTree.new
      @volume_bids_base = 0
      @volume_asks_base = 0
      @volume_bids_quote = 0
      @volume_asks_quote = 0
      @price_points_asks = []
      @price_points_bids = []

      case shape
      when "v"
        shape(method(:amount_v))
      when "w"
        shape(method(:amount_w))
      when "custom"
        shape(method(:amount_custom))
      else
        raise "Invalid shape #{shape}"
      end

      [
        ::Arke::Orderbook::Orderbook.new(
          @market,
          buy:               @bids,
          sell:              @asks,
          volume_bids_quote: @volume_bids_quote,
          volume_asks_quote: @volume_asks_quote,
          volume_bids_base:  @volume_bids_base,
          volume_asks_base:  @volume_asks_base
        ),
        {
          asks: @price_points_asks,
          bids: @price_points_bids
        }
      ]
    end

    def price_step(n)
      case @levels_price_func
      when "constant"
        @levels_price_step
      when "linear"
        (n + 1) * @levels_price_step
      when "exp"
        Math.exp(n) * @levels_price_step
      else
        raise "Invalid levels_price_func #{@levels_price_func}"
      end
    end

    def shape(a)
      current_ask_price = @best_ask_price
      @levels_count.times do |n|
        order = Arke::Order.new(@market, current_ask_price, a.call(n), :sell)
        @asks[order.price] = order.amount
        @volume_asks_base += order.amount
        @volume_asks_quote += order.amount * order.price
        current_ask_price += price_step(n)
        @price_points_asks << ::Arke::PricePoint.new(current_ask_price)
      end

      current_bid_price = @best_bid_price
      @levels_count.times do |n|
        order = Arke::Order.new(@market, current_bid_price, a.call(n), :buy)
        @bids[order.price] = order.amount
        @volume_bids_base += order.amount
        @volume_bids_quote += order.amount * order.price
        current_bid_price -= price_step(n)
        break if current_bid_price.negative?

        @price_points_bids << ::Arke::PricePoint.new(current_bid_price)
      end
    end

    def amount(a)
      a.to_d * (1 + (rand - 0.5) * @random)
    end

    def amount_custom(n)
      amount(n + 1 > @levels.size ? @levels.last : @levels[n])
    end

    def amount_v(n)
      amount(n + 1)
    end

    def amount_w(n)
      case n
      when 0
        amount(1)
      when 1
        amount(2)
      else
        amount(n - 1)
      end
    end
  end
end
