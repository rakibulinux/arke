module Arke::Exchange
  class Bitfinex < Base
    attr_reader :orderbook

    def initialize(opts)
      super
      @ws_url = "wss://%s/ws/2" % opts["host"]
      @orderbook = Arke::Orderbook::Orderbook.new(@market)
      @connection = Faraday.new(:url => "https://#{opts["host"]}") do |builder|
        builder.adapter(opts[:faraday_adapter] || :em_synchrony)
        builder.response :logger if opts["debug"]
        builder.use FaradayMiddleware::ParseJson, :content_type => /\bjson$/
      end
    end

    def info(msg)
      Arke::Log.info "Bitfinex: #{msg}"
    end

    def process_message(msg)
      if msg.kind_of?(Array)
        process_channel_message(msg)
      elsif msg.kind_of?(Hash)
        process_event_message(msg)
      end
    end

    def process_channel_message(msg)
      data = msg[1]

      if data.length == 3
        process_data(data)
      elsif data.length > 3
        data.each { |order| process_data(order) }
      end
    end

    def process_data(data)
      order = new_order(data)
      if data[1].zero?
        @orderbook.delete(order)
      else
        @orderbook.update(order)
      end
    end

    def new_order(data)
      price, _count, amount = data
      side = :buy
      if amount.negative?
        side = :sell
        amount = amount * -1
      end
      Arke::Order.new(@market, price, amount, side)
    end

    def process_event_message(msg)
      case msg["event"]
      when "auth"
      when "subscribed"
        Arke::Log.info "Event: #{msg["event"]}"
      when "unsubscribed"
      when "info"
      when "conf"
      when "error"
        Arke::Log.info "Event: #{msg["event"]} ignored"
      end
    end

    def on_open(e)
      sub = {
        event: "subscribe",
        channel: "book",
        symbol: @market,
        prec: "P0",
        freq: "F0",
      }

      Arke::Log.info "Open event" + sub.to_s
      EM.next_tick {
        @ws.send(JSON.generate(sub))
      }
    end

    def on_message(e)
      msg = JSON.parse(e.data)
      process_message(msg)
    end

    def on_close(e)
      Arke::Log.info "Closing code: #{e.code} Reason: #{e.reason}"
    end

    def build_order(data, side)
      Arke::Order.new(
        @market,
        data["price"].to_f,
        data["amount"].to_f,
        side
      )
    end

    def update_orderbook
      orderbook = Arke::Orderbook::Orderbook.new(@market)
      limit = @opts["limit"] || 1000

      snapshot = @connection.get("/v1/book/#{@market}?limit_bids=#{limit}&limit_asks=#{limit}").body
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
      @orderbook = orderbook
    end

    def markets
      @connection.get("/v1/symbols").body
    end

    def new_trade(data, market)
      amount = data[2]
      pm_id = @platform_markets[market]

      taker_type = :buy
      if amount.negative?
        taker_type = :sell
        amount *= -1
      end

      trade = Trade.new(
        price: data[3],
        amount: amount,
        platform_market_id: pm_id,
        taker_type: taker_type,
      )
      @opts[:on_trade].call(trade, market) if @opts[:on_trade]
    end

    def on_open_trades(market, ws)
      sub = {
        event: "subscribe",
        channel: "trades",
        symbol: market.upcase,
      }

      Arke::Log.info "Open event" + sub.to_s
      EM.next_tick {
        ws.send(JSON.generate(sub))
      }
    end

    def detect_trade(msg)
      market = @connections[msg.first]

      if msg.length == 3 && msg[1] == "te"
        new_trade(msg[2], market)
      end
    end

    def message_event(msg, market)
      case msg["event"]
      when "auth"
      when "subscribed"
        @connections[msg["chanId"]] = market
        Arke::Log.info "Event: #{msg["event"]}"
      when "unsubscribed"
      when "info"
      when "conf"
      when "error"
        Arke::Log.info "Event: #{msg["event"]} ignored"
      end
    end

    def listen_trades(markets_list = nil)
      @connections = {}

      markets_list.each do |market|
        ws = Faye::WebSocket::Client.new(@ws_url)

        ws.on(:open) do |e|
          on_open_trades(market, ws)
        end

        ws.on(:message) do |e|
          msg = JSON.parse(e.data)
          if msg.kind_of?(Array)
            detect_trade(msg)
          elsif msg.kind_of?(Hash)
            message_event(msg, market)
          end
        end

        ws.on(:close) do |e|
          on_close(e)
        end
      end
    end

    def get_balances
      response = authenticated_post("/v1/balances")
      if response.status == 200
        response.body.map do |data|
          {
            "currency" => data['currency'].upcase,
            "free" => data["available"].to_f,
            "locked" => data["amount"].to_f - data["available"].to_f,
            "total" => data["amount"].to_f,
          }
        end
      else
        response.body
      end
    end

    def create_order(order)
      order = {
        symbol: order.market,
        amount: order.amount.to_s,
        price: order.price.to_s,
        side: order.side,
        type: 'limit',
      }
      authenticated_post("/v1/order/new", {params: order}).body
    end

    def fetch_openorders
      orders = authenticated_post("/v1/orders").body
      orders.select { |o| o['symbol'].upcase == @market && o['is_live'] == true }.each do |o|
        order = Arke::Order.new(o['symbol'].upcase, o['price'].to_f, o['remaining_amount'].to_f, o['side'].to_sym)
        @open_orders.add_order(order, o['id'])
      end
      @open_orders
    end

    def start
      update_orderbook

      @ws = Faye::WebSocket::Client.new(@ws_url)

      @ws.on(:open) do |e|
        on_open(e)
      end

      @ws.on(:message) do |e|
        on_message(e)
      end

      @ws.on(:close) do |e|
        on_close(e)
      end
    end

    private

    def build_url(url)
      URI.join(@connection.url_prefix, url)
    end

    def get(url, params = {})
      rest_connection.get do |req|
        req.url build_url(url)
        req.headers["Content-Type"] = "application/json"
        req.headers["Accept"] = "application/json"

        params.each do |k, v|
          req.params[k] = v
        end

        req.options.timeout = config[:rest_timeout]
        req.options.open_timeout = config[:rest_open_timeout]
      end
    end

    def authenticated_post(url, options = {})
      complete_url = build_url(url)
      raise "InvalidAuthKeyError" unless valid_key?
      body = options[:params] || {}
      nonce = new_nonce

      payload = build_payload(url, options[:params], nonce)
      response = @connection.post do |req|
        req.url complete_url
        req.body = body.to_json
        req.headers["Content-Type"] = "application/json"
        req.headers["Accept"] = "application/json"
        req.headers["x-bfx-payload"] = payload
        req.headers["x-bfx-signature"] = sign(payload)
        req.headers["x-bfx-apikey"] = @api_key
      end
    end

    def build_payload(url, params = {}, nonce)
      payload = {}
      payload['nonce'] = nonce
      payload['request'] = url
      payload.merge!(params) if params
      Base64.strict_encode64(payload.to_json)
    end

    def sign(payload)
      OpenSSL::HMAC.hexdigest("sha384", @secret, payload)
    end

    def new_nonce
      (Time.now.to_f * 1000).floor.to_s
    end

    def valid_key?
      !!(@api_key && @secret)
    end
  end
end
