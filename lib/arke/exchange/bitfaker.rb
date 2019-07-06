module Arke::Exchange
  class Bitfaker < Base

    attr_reader :orderbook

    def initialize(opts)
      super
      @path = opts["orderbook"] || File.join(Rails.root, "spec/support/fixtures/bitfinex.yaml")
      @orderbook = Arke::Orderbook::Orderbook.new(@market)
    end

    def start
      load_orderbook
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
    end
  end
end
