module Arke::Exchange
  class Okex < Base
    attr_accessor :orderbook

    def initialize(opts)
      super

      @connection = Faraday.new("https://#{opts['host']}") do |builder|
        builder.adapter(opts[:faraday_adapter] || :em_synchrony)
      end
    end

    def start
    end

    def build_order(data, side)
      Arke::Order.new(
        @market,
        data[0].to_f,
        data[1].to_f,
        side
      )
    end

    def update_orderbook(market)
      orderbook = Arke::Orderbook::Orderbook.new(market)
      snapshot = JSON.parse(@connection.get("api/spot/v3/instruments/#{market}/book").body)

      Array(snapshot['bids']).each do |order|
        orderbook.update(
          build_order(order, :buy)
        )
      end
      Array(snapshot['asks']).each do |order|
        orderbook.update(
          build_order(order, :sell)
        )
      end
      orderbook
    end

    def markets
      JSON.parse(@connection.get("/api/spot/v3/instruments/ticker").body)
      .map { |p| p['instrument_id'] }
    end
  end
end
