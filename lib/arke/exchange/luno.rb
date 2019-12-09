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

    def market_config(market)
      info = symbols_details[market.upcase]
      raise "Pair #{market} not found" unless info

      {
        "id"               => market,
        "base_unit"        => info["base_unit"],
        "quote_unit"       => info["quote_unit"],
        "min_price"        => info["min_price"].to_f,
        "max_price"        => info["max_price"].to_f,
        "min_amount"       => info["min_volume"].to_f,
        "max_amount"       => info["max_volume"].to_f,
        "amount_precision" => info["volume_scale"].to_f,
        "price_precision"  => info["price_scale"].to_f,
      }
    end

    def symbols_details
      {"XBTEUR" =>
                   {"price_scale"       => 2,
                    "volume_scale"      => 4,
                    "min_volume"        => "0.0005",
                    "max_volume"        => "100.00",
                    "min_price"         => "100.00",
                    "max_price"         => "20000.00",
                    "reserve_fee"       => "0.0025",
                    "maker_fee"         => "0.00",
                    "taker_fee"         => "0.0025",
                    "thirty_day_volume" => "0.00",
                    "fee_experiment"    => false,
                    "vol_weight_params" => [-0.111, 0.111],
                    "base_unit"         => "XBT",
                    "quote_unit"        => "EUR"},
       "XBTIDR" =>
                   {"price_scale"       => -3,
                    "volume_scale"      => 6,
                    "min_volume"        => "0.0005",
                    "max_volume"        => "100.00",
                    "min_price"         => "10.00",
                    "max_price"         => "700000000.00",
                    "reserve_fee"       => "0.002",
                    "maker_fee"         => "0.00",
                    "taker_fee"         => "0.002",
                    "thirty_day_volume" => "0.00",
                    "fee_experiment"    => false,
                    "vol_weight_params" => [-0.111, 0.111],
                    "base_unit"         => "XBT",
                    "quote_unit"        => "IDR"},
       "ETHNGN" =>
                   {"price_scale"       => 0,
                    "volume_scale"      => 6,
                    "min_volume"        => "0.005",
                    "max_volume"        => "200.00",
                    "min_price"         => "5000.00",
                    "max_price"         => "10000000.00",
                    "reserve_fee"       => "0.01",
                    "maker_fee"         => "0.00",
                    "taker_fee"         => "0.01",
                    "thirty_day_volume" => "0.00",
                    "fee_experiment"    => false,
                    "vol_weight_params" => [-0.111, 0.111],
                    "base_unit"         => "ETH",
                    "quote_unit"        => "NGN"},
       "ETHZAR" =>
                   {"price_scale"       => 0,
                    "volume_scale"      => 6,
                    "min_volume"        => "0.0005",
                    "max_volume"        => "100.00",
                    "min_price"         => "1000.00",
                    "max_price"         => "10000.00",
                    "reserve_fee"       => "0.01",
                    "maker_fee"         => "0.00",
                    "taker_fee"         => "0.01",
                    "thirty_day_volume" => "0.00",
                    "fee_experiment"    => false,
                    "vol_weight_params" => [-0.111, 0.111],
                    "base_unit"         => "ETH",
                    "quote_unit"        => "ZAR"},
       "XBTMYR" =>
                   {"price_scale"       => 0,
                    "volume_scale"      => 6,
                    "min_volume"        => "0.0005",
                    "max_volume"        => "100.00",
                    "min_price"         => "10000.00",
                    "max_price"         => "150000.00",
                    "reserve_fee"       => "0.01",
                    "maker_fee"         => "0.00",
                    "taker_fee"         => "0.01",
                    "thirty_day_volume" => "0.00",
                    "fee_experiment"    => false,
                    "vol_weight_params" => [-0.111, 0.111],
                    "base_unit"         => "XBT",
                    "quote_unit"        => "MYR"},
       "XBTNGN" =>
                   {"price_scale"       => 0,
                    "volume_scale"      => 6,
                    "min_volume"        => "0.0005",
                    "max_volume"        => "100.00",
                    "min_price"         => "10.00",
                    "max_price"         => "25000000.00",
                    "reserve_fee"       => "0.01",
                    "maker_fee"         => "0.00",
                    "taker_fee"         => "0.01",
                    "thirty_day_volume" => "0.00",
                    "fee_experiment"    => false,
                    "vol_weight_params" => [-0.111, 0.111],
                    "base_unit"         => "XBT",
                    "quote_unit"        => "NGN"},
       "ETHXBT" =>
                   {"price_scale"       => 4,
                    "volume_scale"      => 2,
                    "min_volume"        => "0.01",
                    "max_volume"        => "100.00",
                    "min_price"         => "0.0001",
                    "max_price"         => "1.00",
                    "reserve_fee"       => "0.0025",
                    "maker_fee"         => "0.00",
                    "taker_fee"         => "0.0025",
                    "thirty_day_volume" => "0.00",
                    "fee_experiment"    => false,
                    "vol_weight_params" => [-0.111, 0.0222],
                    "base_unit"         => "ETH",
                    "quote_unit"        => "XBT"},
       "XBTZAR" =>
                   {"price_scale"       => 0,
                    "volume_scale"      => 6,
                    "min_volume"        => "0.0005",
                    "max_volume"        => "100.00",
                    "min_price"         => "10.00",
                    "max_price"         => "1000000.00",
                    "reserve_fee"       => "0.01",
                    "maker_fee"         => "0.00",
                    "taker_fee"         => "0.01",
                    "thirty_day_volume" => "0.00",
                    "fee_experiment"    => false,
                    "vol_weight_params" => [-0.111, 0.111],
                    "base_unit"         => "XBT",
                    "quote_unit"        => "ZAR"},
       "XBTZMW" =>
                   {"price_scale"       => 0,
                    "volume_scale"      => 6,
                    "min_volume"        => "0.0005",
                    "max_volume"        => "100.00",
                    "min_price"         => "10.00",
                    "max_price"         => "1000000.00",
                    "reserve_fee"       => "0.01",
                    "maker_fee"         => "0.00",
                    "taker_fee"         => "0.01",
                    "thirty_day_volume" => "0.00",
                    "fee_experiment"    => false,
                    "vol_weight_params" => [-0.111, 0.111],
                    "base_unit"         => "XBT",
                    "quote_unit"        => "ZMW"},
       "XBTSGD" =>
                   {"price_scale"       => 2,
                    "volume_scale"      => 4,
                    "min_volume"        => "0.0005",
                    "max_volume"        => "100.00",
                    "min_price"         => "1000.00",
                    "max_price"         => "100000.00",
                    "reserve_fee"       => "0.0055",
                    "maker_fee"         => "0.00",
                    "taker_fee"         => "0.0055",
                    "thirty_day_volume" => "0.00",
                    "fee_experiment"    => false,
                    "vol_weight_params" => [-0.111, 0.111],
                    "base_unit"         => "XBT",
                    "quote_unit"        => "SGD"},
       "XBTUGX" =>
                   {"price_scale"       => -3,
                    "volume_scale"      => 6,
                    "min_volume"        => "0.0005",
                    "max_volume"        => "100.00",
                    "min_price"         => "1000.00",
                    "max_price"         => "200000000.00",
                    "reserve_fee"       => "0.0025",
                    "maker_fee"         => "0.00",
                    "taker_fee"         => "0.0025",
                    "thirty_day_volume" => "0.00",
                    "fee_experiment"    => false,
                    "vol_weight_params" => [-0.111, 0.111],
                    "base_unit"         => "XBT",
                    "quote_unit"        => "UGX"},
       "BCHXBT" =>
                   {"price_scale"       => 4,
                    "volume_scale"      => 2,
                    "min_volume"        => "0.01",
                    "max_volume"        => "100.00",
                    "min_price"         => "0.0001",
                    "max_price"         => "1.00",
                    "reserve_fee"       => "0.0025",
                    "maker_fee"         => "0.00",
                    "taker_fee"         => "0.0025",
                    "thirty_day_volume" => "0.00",
                    "fee_experiment"    => false,
                    "vol_weight_params" => [-0.111, 0.111],
                    "base_unit"         => "BCH",
                    "quote_unit"        => "XBT"}}
    end
  end
end
