module Arke::Exchange
  class Kraken < Base
    attr_accessor :orderbook

    def initialize(opts)
      super
      if opts[:enable_ws]
        ws_url = "wss://ws-beta.kraken.com"
        @ws = Faye::WebSocket::Client.new(ws_url)
      end
      rest_url = "https://#{opts['host']}"
      @rest_conn = Faraday.new(rest_url) do |builder|
        builder.adapter(opts[:faraday_adapter] || :em_synchrony)
      end
      kraken_pair
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
      snapshot = JSON.parse(@rest_conn.get("/0/public/Depth?pair=#{market.upcase}").body)
      result = snapshot['result']
      return orderbook if result.nil? or result.values.nil?

      Array(result.values.first['bids']).each do |order|
        orderbook.update(build_order(order, :buy))
      end
      Array(result.values.first['asks']).each do |order|
        orderbook.update(build_order(order, :sell))
      end

      orderbook
    end

    def kraken_pair
      @kraken_pair ||= JSON.parse(@rest_conn.get("/0/public/AssetPairs").body)
    end

    def markets
      @markets ||= kraken_pair['result'].values.each_with_object([]) do |p, arr|
        arr << p['altname'].downcase
      end
    end

    def markets_ws_map
      @markets_ws_map ||= kraken_pair['result'].values.each_with_object({}) do |p, h|
        h[p['altname'].downcase] = p['wsname']
      end
    end

    def on_open_trades(markets_list)
      ws_markets = markets_list.map { |market| markets_ws_map[market] }
      sub = {
        "event": "subscribe",
        "pair": ws_markets,
        "subscription": {
          "name": "trade"
        }
      }

      info "Open event #{sub}"
      EM.next_tick {
        @ws.send(JSON.generate(sub))
      }
    end

    def new_trade(msg)
      data = msg[1]
      market = msg.last
      pm_id = @platform_markets[market]
      data.each do |t|
        taker_type = t[3] == 'b' ? :buy : :sell
        trade = Trade.new(
          price: t[0],
          amount: t[1],
          platform_market_id: pm_id,
          taker_type: taker_type,
          created_at: t[2],
        )
        @opts[:on_trade].call(trade, market) if @opts[:on_trade]
      end
    end

    def on_close(e)
      info "Closing code: #{e.code}: #{e}"
    end

    def listen_trades(markets_list = nil)
      info "Connecting to websocket: #{@ws_url}"

      @ws.on(:open) do |e|
        on_open_trades(markets_list)
      end

      @ws.on(:message) do |e|
        msg = JSON.parse(e.data)
        new_trade(msg) if msg.kind_of?(Array)
      end

      @ws.on(:close) do |e|
        on_close(e)
      end
    end
  end
end
