# frozen_string_literal: true

module Arke::Exchange
  class Bitfaker < Base
    attr_reader :orderbook

    def initialize(opts)
      super
      @path = opts["orderbook"] || File.join("./spec/support/fixtures/bitfinex.yaml")
    end

    def cancel_all_orders(_market)
      puts "order cancelled"
    end

    def create_order(order)
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
      [
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

    def get_market_infos(_market)
      {
        "id"               => "BTCUSD",
        "name"             => "BTC/USD",
        "base_unit"        => "BTC",
        "quote_unit"       => "USD",
        "ask_fee"          => "0.0002",
        "bid_fee"          => "0.0002",
        "min_price"        => "0.0",
        "max_price"        => "0.0",
        "min_amount"       => "0.00001",
        "amount_precision" => 6,
        "price_precision"  => 6,
        "state"            => "enabled",
      }
    end

    def update_orderbook(market)
      orders = YAML.load_file(@path)[1]
      orderbook = Arke::Orderbook::Orderbook.new(market)
      orders.each do |o|
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
      YAML.load_file(@path)[1].each do |o|
        ord = build_order(o, market)
        ord.id = o[0]
        orders << ord
      end
      orders
    end

    def ping; end

    private

    def add_order(order)
      _id, price, amount = order
      side = amount.negative? ? :sell : :buy
      amount = amount.abs
    end
  end
end
