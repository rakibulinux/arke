# frozen_string_literal: true

require "bitx"
module BitX
  class Configuration
    attr_accessor :api_key_id, :api_key_secret, :api_key_pin, :adapter, :debug
  end

  def self.conn
    return @conn if @conn

    @conn = Faraday.new(url: "https://api.mybitx.com") do |builder|
      builder.adapter(configuration.adapter)
      builder.response :logger if configuration.debug == true
    end
    @conn.headers[:user_agent] = "bitx-ruby/#{BitX::VERSION::STRING}"
    @conn
  end
end

module Arke::Exchange
  class Luno < Base
    attr_accessor :orderbook

    def initialize(opts)
      super
      BitX.configure do |config|
        config.api_key_secret = @secret
        config.api_key_id = @api_key
        config.adapter = opts[:faraday_adapter] || :em_synchrony
        config.debug = true if opts["debug"]
      end
    end

    def start; end

    def build_order(data, side)
      Arke::Order.new(
        @market,
        data[:price].to_f,
        data[:volume].to_f,
        side
      )
    end

    def get_balances
      BitX.balance.map do |data|
        {
          "currency" => data[:asset],
          "free"     => data[:balance].to_f,
          "locked"   => data[:reserved].to_f,
          "total"    => data[:balance].to_f + data[:reserved].to_f,
        }
      end
    end

    def update_orderbook(market)
      orderbook = Arke::Orderbook::Orderbook.new(market)
      snapshot = BitX.orderbook(market)
      snapshot[:bids].each do |order|
        orderbook.update(
          build_order(order, :buy)
        )
      end
      snapshot[:asks].each do |order|
        orderbook.update(
          build_order(order, :sell)
        )
      end
      orderbook
    end

    def markets
      BitX.tickers.map {|t| t[:pair] }
    end

    def create_order(order)
      type = order.side == :buy ? "BID" : "ASK"
      params = {
        pair:   order.market.upcase,
        type:   type,
        volume: order.amount.to_f,
        price:  order.price.to_f
      }
      path = "/api/1/postorder"
      BitX.conn.basic_auth(@api_key, @secret)
      BitX.conn.post(path, params)
    end
  end
end
