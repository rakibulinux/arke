# frozen_string_literal: true

module Arke::Exchange
  class Bitfaker < Base
    attr_reader :orderbook

    def initialize(opts)
      super

      @orders = if opts["orderbook"].is_a?(Array)
                  opts["orderbook"][1]
                elsif opts["orderbook"].is_a?(String)
                  YAML.load_file(opts["orderbook"])[1]
                else
                  YAML.load_file("./spec/fixtures/files/bitfinex.yaml")[1]
                end
      if opts["params"] && opts["params"]["balances"]
        @balances = opts["params"]["balances"]
      else
        @balances = [
          {
            "currency" => "BTC",
            "total"    => 4_723_846.89208129,
            "free"     => 4_723_846.89208129,
            "locked"   => 0.0,
          },
          {
            "currency" => "USD",
            "total"    => 4_763_468.68006011,
            "free"     => 4_763_368.68006011,
            "locked"   => 100.0,
          }
        ]
      end
    end

    def ws_connect(ws_id)
      logger.info { "ACCOUNT:#{id} Websocket faking connection to #{ws_id}" }
      @ws = true
    end

    def cancel_all_orders(_market)
      logger.info { "ACCOUNT:#{id} all orders cancelled" }
    end

    def create_order(order)
      raise "ACCOUNT:#{id} amount_s is nil" if order.amount_s.nil?
      raise "ACCOUNT:#{id} price_s is nil" if order.price_s.nil? && order.type == "limit"

      pp order
      response = OpenStruct.new
      response.env = OpenStruct.new
      response.status = 200
      response.env.body = {
        "id" => rand(1..1000)
      }
      response
    end

    def stop_order(order)
      pp order
    end

    def get_balances
      @balances
    end

    def market_config(market)
      base, quote = market.include?("/") ? market.split("/") : [market[0..2], market[3..5]]
      {
        "id"               => market,
        "base_unit"        => base,
        "quote_unit"       => quote,
        "min_price"        => 0.0,
        "max_price"        => 0.0,
        "min_amount"       => 0.1,
        "amount_precision" => 6,
        "price_precision"  => 6,
        "min_order_size"   => nil,
      }
    end

    def update_orderbook(market)
      orderbook = Arke::Orderbook::Orderbook.new(market)
      @orders.each do |o|
        ord = build_order(o, market)
        orderbook.update(ord)
      end
      orderbook
    end

    def build_order(data, market)
      side = data[2].negative? ? :sell : :buy
      amount = data[2].abs
      Arke::Order.new(
        market,
        data[1].to_f,
        amount,
        side
      )
    end

    def fetch_openorders(market)
      orders = []
      @orders.each do |o|
        ord = build_order(o, market)
        ord.id = o[0]
        orders << ord
      end
      orders
    end

    def ping; end

    private

    def add_order(order)
      _id, _price, amount = order
      amount.abs
    end
  end
end
