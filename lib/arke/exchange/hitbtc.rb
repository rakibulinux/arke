# frozen_string_literal: true

module Arke::Exchange
  class Hitbtc < Base
    attr_accessor :orderbook

    def initialize(opts)
      super

      @ws_url = "wss://#{opts['host']}/api/2/ws"
      @connection = Faraday.new("https://#{opts['host']}") do |builder|
        builder.use FaradayMiddleware::ParseJson, content_type: /\bjson$/
        builder.adapter(@adapter)
      end
      @connection.basic_auth(@api_key, @secret)
    end

    def start; end

    def build_order(data, side)
      Arke::Order.new(
        @market,
        data["price"].to_f,
        data["size"].to_f,
        side
      )
    end

    def update_orderbook(market)
      orderbook = Arke::Orderbook::Orderbook.new(market)
      snapshot = @connection.get("/api/2/public/orderbook/#{market.upcase}").body
      Array(snapshot["bid"]).each do |order|
        orderbook.update(
          build_order(order, :buy)
        )
      end
      Array(snapshot["ask"]).each do |order|
        orderbook.update(
          build_order(order, :sell)
        )
      end
      orderbook
    end

    def get_balances
      balances = @connection.get("/api/2/trading/balance").body
      balances.map do |data|
        {
          "currency" => data["currency"],
          "free"     => data["available"].to_f,
          "locked"   => data["reserved"].to_f,
          "total"    => data["available"].to_f + data["reserved"].to_f,
        }
      end
    end

    def create_order(order)
      ord = {
        symbol:   order.market.upcase,
        side:     order.side,
        quantity: order.amount,
        price:    order.price
      }
      @connection.post do |req|
        req.url "/api/2/order"
        req.body = ord
      end
    end

    def symbols
      @symbols ||= @connection.get("/api/2/public/symbol").body
    end

    def markets
      symbols.map {|s| s["id"] }
    end

    def market_config(market)
      market_infos = symbols.find {|s| s["id"] == market }
      raise "Symbol #{market} not found" unless market_infos

      {
        "id"               => market_infos.fetch("id"),
        "base_unit"        => market_infos["baseCurrency"],
        "quote_unit"       => market_infos["quoteCurrency"],
        "min_price"        => nil,
        "max_price"        => nil,
        "min_amount"       => market_infos["quantityIncrement"].to_f,
        "amount_precision" => value_precision(market_infos["quantityIncrement"].to_f),
        "price_precision"  => value_precision(market_infos["tickSize"].to_f),
      }
    end

    def on_open_trades(markets_list=nil)
      markets_list.each do |market|
        sub = {
          method: "subscribeTrades",
          params: {
            symbol: market.upcase,
            limit:  1
          },
          id:     1
        }

        info "Open event" + sub.to_s
        EM.next_tick {
          @ws.send(JSON.generate(sub))
        }
      end
    end

    def detect_trades(msg)
      market = msg["params"]["symbol"]
      pm_id = @platform_markets[market]
      msg["params"]["data"].each do |t|
        trade = Trade.new(
          price:              t["price"],
          amount:             t["quantity"],
          taker_type:         t["side"],
          platform_market_id: pm_id
        )
        @opts[:on_trade]&.call(trade, market)
      end
    end

    def on_close(e)
      info "Closing code: #{e.code} Reason: #{e.reason}"
    end

    def listen_trades(markets_list=nil)
      @ws = Faye::WebSocket::Client.new(@ws_url)

      @ws.on(:open) do |_e|
        on_open_trades(markets_list)
      end

      @ws.on(:message) do |e|
        msg = JSON.parse(e.data)
        detect_trades(msg) if msg["method"] == "updateTrades"
      end

      @ws.on(:close) do |e|
        on_close(e)
      end
    end
  end
end
