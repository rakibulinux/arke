# frozen_string_literal: true

module Arke::Exchange
  class Recorder < Base
    attr_reader :orderbook

    def initialize(opts)
      super

      @uid = opts["params"]["uid"] || "U487205863"
      output = opts["params"]["output"] || "actions.yml"
      @output = File.open(output, "w")
      @open_orders = []

      @balances = if opts["params"] && opts["params"]["balances"]
                    opts["params"]["balances"]
                  else
                    [
                      {
                        "currency" => "BTC",
                        "total"    => 10,
                        "free"     => 10,
                        "locked"   => 0.0,
                      },
                      {
                        "currency" => "USD",
                        "total"    => 200_000,
                        "free"     => 200_000,
                        "locked"   => 0.0,
                      }
                    ]
                  end

      @order_id = 1
    end

    def ws_connect(_)
      @ws_connected = true
      @ws = true
    end

    def cancel_all_orders(_market); end

    def create_order(order)
      raise "ACCOUNT:#{id} amount_s is nil" if order.amount_s.nil?
      raise "ACCOUNT:#{id} price_s is nil" if order.price_s.nil? && order.type == "limit"

      @output.write("- create_order: {uid: #{@uid}, market: #{order.market}, side: #{order.side}, type: #{order.type}, amount: %f, price: %f}\n" % [order.amount, order.price])
      order.id = @order_id
      @open_orders << order
      response = OpenStruct.new
      response.env = OpenStruct.new
      response.status = 200
      response.env.body = {
        "id" => @order_id
      }
      @order_id += 1
      notify_created_order(order)
      response
    end

    def stop_order(order)
      @output.write("- cancel_order: {uid: #{@uid}, id: #{order.id}}\n")
      @open_orders.delete_if {|o| o.id == order.id }
      notify_deleted_order(order)
    end

    def get_balances
      @balances
    end

    def market_config(_market)
      {
        "id"               => "btcusd",
        "base_unit"        => "btc",
        "quote_unit"       => "usd",
        "min_price"        => 0.0,
        "max_price"        => 0.0,
        "min_amount"       => 0.000001,
        "amount_precision" => 6,
        "price_precision"  => 2,
      }
    end

    def update_orderbook(market)
      Arke::Orderbook::Orderbook.new(market)
    end

    def fetch_openorders(market)
      @open_orders
    end

    def ping; end
  end
end
