# frozen_string_literal: true

module Arke::Exchange
  class Binance < Base
    attr_reader :last_update_id
    attr_accessor :orderbook

    def initialize(opts)
      super
      @host ||= "https://api.binance.com"
      @client = ::Binance::Client::REST.new(api_key: @api_key, secret_key: @secret, adapter: @adapter)
      @min_notional = {}
      @min_quantity = {}
      @base_precision = {}
      @markets = opts["markets"]
    end

    def ws_connect_public
      streams = markets.map {|market| "#{market.downcase}@aggTrade.b10" }.join("/")
      @ws_url = "wss://stream.binance.com:9443/stream?streams=#{streams}"
      ws_connect(:public)
    end

    def ws_read_public_message(msg)
      d = msg["data"]
      case d["e"]
      # "m": true, Is the buyer the market maker?
      # in API we expose taker_type
      when "aggTrade"
        trade = ::Arke::PublicTrade.new
        trade.id = d["a"]
        trade.market = d["s"]
        trade.exchange = "binance"
        trade.taker_type = d["m"] ? "sell" : "buy"
        trade.amount = d["q"]
        trade.price = d["p"]
        trade.total = trade.total
        trade.created_at = d["T"]
      when "trade"
        trade = ::Arke::PublicTrade.new
        trade.id = d["t"]
        trade.market = d["s"]
        trade.exchange = "binance"
        trade.taker_type = d["m"] ? "sell" : "buy"
        trade.amount = d["q"]
        trade.price = d["p"]
        trade.total = trade.total
      else
        raise "Unsupported event type #{d['e']}"
      end
      notify_public_trade(trade)
    end

    def build_order(data, side)
      Arke::Order.new(
        @market,
        data[0].to_f,
        data[1].to_f,
        side
      )
    end

    def new_trade(data)
      taker_type = data["b"] > data["a"] ? :buy : :sell
      market = data["s"]
      pm_id = @platform_markets[market]

      trade = Trade.new(
        price:              data["p"],
        amount:             data["q"],
        platform_market_id: pm_id,
        taker_type:         taker_type
      )
      @opts[:on_trade]&.call(trade, market)
    end

    def update_orderbook(market)
      orderbook = Arke::Orderbook::Orderbook.new(market)
      limit = @opts["limit"] || 1000
      snapshot = @client.depth(symbol: market.upcase, limit: limit)
      Array(snapshot["bids"]).each do |order|
        orderbook.update(
          build_order(order, :buy)
        )
      end
      Array(snapshot["asks"]).each do |order|
        orderbook.update(
          build_order(order, :sell)
        )
      end
      orderbook
    end

    def markets
      return @markets if @markets.present?

      @client.exchange_info["symbols"]
             .filter {|s| s["status"] == "TRADING" }
             .map {|s| s["symbol"] }
    end

    def get_amount(order)
      min_notional = @min_notional[order.market] ||= get_min_notional(order.market)
      base_precision = @base_precision[order.market] ||= get_base_precision(order.market)
      percentage = 0.2
      notional = order.price * order.amount
      if notional > min_notional
        order.amount
      elsif (min_notional * percentage) < notional
        return (min_notional / order.price).ceil(base_precision)
      else
        raise "Amount of order too small"
      end
    end

    def create_order(order)
      amount = get_amount(order)
      return if amount.zero?

      raw_order = {
        symbol:        order.market.upcase,
        side:          order.side.upcase,
        type:          "LIMIT",
        time_in_force: "GTC",
        quantity:      amount,
        price:         order.price,
      }
      @client.create_order!(raw_order)
    end

    def get_balances
      balances = @client.account_info["balances"]
      balances.map do |data|
        {
          "currency" => data["asset"],
          "free"     => data["free"].to_f,
          "locked"   => data["locked"].to_f,
          "total"    => data["free"].to_f + data["locked"].to_f,
        }
      end
    end

    def fetch_openorders(market)
      @client.open_orders(symbol: market).map do |o|
        remaining_volume = o["origQty"].to_f - o["executedQty"].to_f
        Arke::Order.new(
          o["symbol"],
          o["price"].to_f,
          remaining_volume,
          o["side"].downcase.to_sym,
          o["type"].downcase.to_sym,
          o["orderId"]
        )
      end
    end

    def get_base_precision(market)
      min_quantity = @min_quantity[market] ||= get_min_quantity(market)
      return 0 if min_quantity >= 1

      n = 0
      while min_quantity < 1
        n += 1
        min_quantity *= 10
      end
      n
    end

    def get_min_quantity(market)
      @client.exchange_info["symbols"]
             .find {|s| s["symbol"] == market }["filters"]
             .find {|f| f["filterType"] == "LOT_SIZE" }["minQty"].to_f
    end

    def get_min_notional(market)
      @client.exchange_info["symbols"]
             .find {|s| s["symbol"] == market }["filters"]
             .find {|f| f["filterType"] == "MIN_NOTIONAL" }["minNotional"].to_f
    end
  end
end
