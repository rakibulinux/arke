module Arke::Exchange
  class Binance < Base
    attr_reader :last_update_id
    attr_accessor :orderbook

    def initialize(opts)
      super
      @ws_url = "wss://stream.binance.com:9443/ws/#{@market}@depth"
      @client = ::Binance::Client::REST.new(api_key: @api_key, secret_key: @secret, adapter: @adapter)
    end

    def start
      update_orderbook
      @ws = Faye::WebSocket::Client.new(@ws_url)
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
      taker_type = data['b'] > data['a'] ? :buy : :sell
      market = data['s']
      pm_id = @platform_markets[market]

      trade = Trade.new(
        price: data['p'],
        amount: data['q'],
        platform_market_id: pm_id,
        taker_type: taker_type
      )
      @opts[:on_trade].call(trade, market) if @opts[:on_trade]
    end

    def listen_trades(markets_list = nil)
      markets_list.each do |market|
        ws = Faye::WebSocket::Client.new("wss://stream.binance.com:9443/ws/#{market.downcase}@trade")

        ws.on(:message) do |e|
          msg = JSON.parse(e.data)
          new_trade(msg)
        end
      end
    end

    def update_orderbook
      orderbook = Arke::Orderbook::Orderbook.new(@market)
      limit = @opts["limit"] || 1000
      snapshot = @client.depth(symbol: @market.upcase, limit: limit)
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
      @orderbook = orderbook
    end

    def markets
      @client.exchange_info["symbols"]
      .filter { |s| s["status"] == "TRADING" }
      .map { |s| s["symbol"] }
    end

    def get_amount(order)
      @min_notional = get_min_notional unless @min_notional
      percentage = 0.2
      notional = order.price * order.amount
      if notional > @min_notional
        order.amount
      elsif (@min_notional * percentage) < notional
        amount = (@min_notional/order.price).ceil(@base_precision.to_f)
      else
        raise "Amount of order too small"
      end
    end

    def create_order(order)
      amount = get_amount(order)
      unless amount == 0
        raw_order = {
          symbol: @market.upcase,
          side: order.side.upcase,
          type: 'LIMIT',
          time_in_force: 'GTC',
          quantity: amount,
          price: order.price,
        }
        pp raw_order
        @client.create_order!(raw_order)
      end
    end

    def get_balances
      balances = @client.account_info["balances"]
      balances.map do |data|
        {
          "currency" => data["asset"],
          "free" => data["free"].to_f,
          "locked" => data["locked"].to_f,
          "total" => data["free"].to_f + data["locked"].to_f,
        }
      end
    end

    def fetch_openorders
      @client.open_orders(symbol: @market).each do |o|
        remaining_volume = o["origQty"].to_f - o["executedQty"].to_f
        order = Arke::Order.new(o["symbol"], o["price"].to_f, remaining_volume, o["side"].downcase.to_sym)
        order.id = o["orderId"]
        @open_orders.add_order(order)
      end
      @open_orders
    end

    def get_min_notional
      @client.exchange_info['symbols']
        .find { |s| s["symbol"] == @market }['filters']
        .find { |f| f['filterType'] == 'MIN_NOTIONAL' }['minNotional'].to_f
    end
  end
end
