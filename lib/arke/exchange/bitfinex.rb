# frozen_string_literal: true

module Arke::Exchange
  class Bitfinex < Base
    attr_reader :orderbook

    def initialize(opts)
      super
      opts["host"] ||= "api.bitfinex.com"
      @ws_url = "wss://%s/ws/1" % opts["host"]
      @connection = Faraday.new(url: "https://#{opts['host']}") do |builder|
        builder.response :json
        builder.response :logger if opts["debug"]
        builder.adapter(@adapter)
      end
      @markets = opts["markets"]
    end

    def ws_connect(ws_id)
      super(ws_id)

      @ws.on(:open) do |_e|
        if flag?(LISTEN_PUBLIC_TRADES)
          @markets_to_listen.each do |market|
            subscribe_trades(market, ws)
          end
        end

        Fiber.new do
          EM::Synchrony.add_periodic_timer(80) do
            ws_write_message(ws_id, '{"event":"ping"}')
          end
        end.resume
      end
    end

    def subscribe_trades(market, ws)
      sub = {
        event:   "subscribe",
        channel: "trades",
        symbol:  market.upcase,
      }

      Arke::Log.info "Open event" + sub.to_s
      EM.next_tick {
        ws.send(JSON.generate(sub))
      }
    end

    def ws_read_public_message(msg)
      if msg.is_a?(Array)
        detect_trade(msg)
      elsif msg.is_a?(Hash)
        message_event(msg)
      end
    end

    def detect_trade(msg)
      if msg[1] == "tu"
        market = msg[2].split("-").last
        amount = msg[6].to_d
        trade = ::Arke::PublicTrade.new(
          msg[3],
          market,
          "bitfinex",
          amount.positive? ? "buy" : "sell",
          amount.abs,
          msg[5],
          (msg[5].to_d * amount).abs,
          msg[4].to_i * 1000
        )
        notify_public_trade(trade)
      end
    end

    def message_event(msg)
      case msg["event"]
      # when "auth"
      when "subscribed"
        Arke::Log.info "Event: #{msg}"
      # when "unsubscribed"
      # when "info"
      # when "conf"
      when "error"
        Arke::Log.info "Event: #{msg} ignored"
      end
    end

    def info(msg)
      Arke::Log.info "Bitfinex: #{msg}"
    end

    def process_message(msg)
      if msg.is_a?(Array)
        process_channel_message(msg)
      elsif msg.is_a?(Hash)
        process_event_message(msg)
      end
    end

    def process_channel_message(msg)
      data = msg[1]

      if data.length == 3
        process_data(data)
      elsif data.length > 3
        data.each {|order| process_data(order) }
      end
    end

    def process_data(data)
      order = new_order(data)
      if data[1].zero?
        @deleted_order.call(order)
      else
        @created_order.call(order)
      end
    end

    def new_order(data)
      price, _count, amount = data
      side = :buy
      if amount.negative?
        side = :sell
        amount *= -1
      end
      Arke::Order.new(@market, price, amount, side)
    end

    def process_event_message(msg)
      case msg["event"]
      # when "auth"
      when "subscribed"
        Arke::Log.info "Event: #{msg['event']}"
      # when "unsubscribed"
      # when "info"
      # when "conf"
      when "error"
        Arke::Log.info "Event: #{msg['event']} ignored"
      end
    end

    def build_order(data, side)
      Arke::Order.new(
        @market,
        data["price"].to_f,
        data["amount"].to_f,
        side
      )
    end

    def update_orderbook(market)
      orderbook = Arke::Orderbook::Orderbook.new(market)
      limit = @opts["limit"] || 1000

      snapshot = @connection.get("/v1/book/#{market}?limit_bids=#{limit}&limit_asks=#{limit}").body
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
      @connection.get("/v1/symbols").body
    end

    def symbols_details
      @symbols_details ||= @connection.get("/v1/symbols_details").body
    end

    def market_config(market)
      info = symbols_details&.find {|i| i["pair"].downcase == market.downcase }
      raise "Pair #{market} not found" unless info

      market_id = info.fetch("pair")
      if market_id.include?(":")
        base, quote = market_id.split(":")
      elsif market_id.size == 6
        base = market_id[0..2]
        quote = market_id[3..5]
      else
        base = nil
        quote = nil
      end
      {
        "id"               => market_id,
        "base_unit"        => base,
        "quote_unit"       => quote,
        "min_price"        => nil,
        "max_price"        => nil,
        "min_amount"       => info.fetch("minimum_order_size").to_d,
        "amount_precision" => 8,
        "price_precision"  => info.fetch("price_precision").to_d,
      }
    end

    def get_balances
      response = authenticated_post("/v1/balances")
      if response.status == 200
        response.body.map do |data|
          {
            "currency" => data["currency"].upcase,
            "free"     => data["available"].to_f,
            "locked"   => data["amount"].to_f - data["available"].to_f,
            "total"    => data["amount"].to_f,
          }
        end
      else
        response.body
      end
    end

    def create_order(order)
      raise "ACCOUNT:#{id} amount_s is nil" if order.amount_s.nil?
      raise "ACCOUNT:#{id} price_s is nil" if order.price_s.nil? && order.type == "limit"

      params = {
        symbol: order.market,
        amount: order.amount_s,
        side:   order.side,
      }

      if order.type == "post_only"
        order.type = "limit"
        params[:is_postonly] = true
      end

      params[:type] = "exchange #{order.type}"
      params[:price] = order.price_s

      authenticated_post("/v1/order/new", params: params).body
    end

    def fetch_openorders(market)
      orders = authenticated_post("/v1/orders").body
      orders.select {|o| o["symbol"].upcase == market && o["is_live"] == true }.map do |o|
        order = Arke::Order.new(o["symbol"].upcase, o["price"].to_f, o["remaining_amount"].to_f, o["side"].to_sym)
        order.id = o["id"]
        order
      end
    end

    private

    def build_url(url)
      URI.join(@connection.url_prefix, url)
    end

    def get(url, params={})
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

    def authenticated_post(url, options={})
      complete_url = build_url(url)
      raise "InvalidAuthKeyError" unless valid_key?

      body = options[:params] || {}
      nonce = new_nonce

      payload = build_payload(url, options[:params], nonce)
      @connection.post do |req|
        req.url complete_url
        req.body = body.to_json
        req.headers["Content-Type"] = "application/json"
        req.headers["Accept"] = "application/json"
        req.headers["x-bfx-payload"] = payload
        req.headers["x-bfx-signature"] = sign(payload)
        req.headers["x-bfx-apikey"] = @api_key
      end
    end

    def build_payload(url, params, nonce)
      payload = {}
      payload["nonce"] = nonce
      payload["request"] = url
      payload.merge!(params) if params
      Base64.strict_encode64(payload.to_json)
    end

    def sign(payload)
      OpenSSL::HMAC.hexdigest("sha384", @secret, payload)
    end

    def new_nonce
      (Time.now.to_f * 1000).floor.to_s
    end
  end
end
