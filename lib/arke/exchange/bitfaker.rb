module Arke::Exchange
  class Bitfaker < Base

    attr_reader :orderbook

    def initialize(opts)
      super
      @path = opts["orderbook"] || File.join("./spec/support/fixtures/bitfinex.yaml")
      @orderbook = Arke::Orderbook::Orderbook.new(@market)
      @open_orders = Arke::Orderbook::OpenOrders.new(@market)
    end

    def start
      load_orderbook
    end

    def cancel_all_orders
      puts "order cancelled"
    end

    def create_order(order)
      pp order
    end

    def stop_order(order)
      pp order
    end

    def get_balances
      [
        {
          "currency" => "BTC",
          "total" => 4723846.89208129,
          "free" => 4723846.89208129,
          "locked" => 0.0,
        },
        {
          "currency" => "USD",
          "total" => 4763468.68006011,
          "free" => 4763368.68006011,
          "locked" => 100.0,
        }
      ]
    end

    def get_market_infos
      {
        "id" => "btcusd",
        "name" => "BTC/USD",
        "base_unit" => "BTC",
        "quote_unit" => "USD",
        "ask_fee" => "0.0002",
        "bid_fee" => "0.0002",
        "min_price" => "0.0",
        "max_price" => "0.0",
        "min_amount" => "0.00001",
        "amount_precision" => 6,
        "price_precision" => 6,
        "state" => "enabled",
      }
    end

    def update_orderbook
      load_orderbook
    end

    def ping; end

    private

    def load_orderbook
      raise "File #{@path} not found" unless File.exist?(@path)
      fixture = YAML.load_file(@path)
      orders = fixture[1]
      orders.each { |order| add_order(order) }
    end

    def add_order(order)
      _id, price, amount = order
      side = (amount.negative?) ? :sell : :buy
      amount = amount.abs
      @orderbook.update(Arke::Order.new(@market, price, amount, side))
      @open_orders.add_order(Arke::Order.new(@market, price, amount, side, 'limit', _id))
    end
  end
end
