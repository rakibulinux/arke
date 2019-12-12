# frozen_string_literal: true

module Arke::Exchange
  class Kraken < Base
    attr_accessor :orderbook

    def initialize(opts)
      super
      if opts[:enable_ws]
        ws_url = "wss://ws-beta.kraken.com"
        @ws = Faye::WebSocket::Client.new(ws_url)
      end
      @api_secret = opts["secret"]
      @api_key = opts["key"]
      opts["host"] ||= "api.kraken.com"
      rest_url = "https://#{opts['host']}"
      @rest_conn = Faraday.new(rest_url) do |builder|
        builder.response :logger, logger if opts["debug"]
        builder.use FaradayMiddleware::ParseJson, content_type: /\bjson$/
        builder.adapter(opts[:faraday_adapter] || :em_synchrony)
      end
      symbols
    end

    def start; end

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
      snapshot = @rest_conn.get("/0/public/Depth?pair=#{market.upcase}").body
      result = snapshot["result"]
      return orderbook if result.nil? || result.values.nil?

      Array(result.values.first["bids"]).each do |order|
        orderbook.update(build_order(order, :buy))
      end
      Array(result.values.first["asks"]).each do |order|
        orderbook.update(build_order(order, :sell))
      end

      orderbook
    end

    def symbols
      @symbols ||= @rest_conn.get("/0/public/AssetPairs").body["result"]
    end

    def markets
      @markets ||= symbols.values.each_with_object([]) do |p, arr|
        arr << p["altname"].downcase
      end
    end

    def currencies
      @currencies ||= @rest_conn.get("/0/public/Assets").body["result"].map do |_k, c|
        {
          "id"   => c["altname"],
          "type" => "coin",
        }
      end
    end

    def market_config(market)
      market_infos = symbols.find {|_, s| s["altname"] == market }&.last
      raise "Symbol #{market} not found" unless market_infos

      {
        "id"               => market_infos.fetch("altname"),
        "base_unit"        => market_infos["base"],
        "quote_unit"       => market_infos["quote"],
        "min_price"        => nil,
        "max_price"        => nil,
        "min_amount"       => nil,
        "amount_precision" => market_infos["lot_decimals"],
        "price_precision"  => market_infos["pair_decimals"],
      }
    end

    def markets_ws_map
      @markets_ws_map ||= symbols.values.each_with_object({}) do |p, h|
        h[p["altname"].downcase] = p["wsname"]
      end
    end

    def on_open_trades(markets_list)
      ws_markets = markets_list.map {|market| markets_ws_map[market] }
      sub = {
        "event":        "subscribe",
        "pair":         ws_markets,
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
        taker_type = t[3] == "b" ? :buy : :sell
        trade = Trade.new(
          price:              t[0],
          amount:             t[1],
          platform_market_id: pm_id,
          taker_type:         taker_type,
          created_at:         t[2]
        )
        @opts[:on_trade]&.call(trade, market)
      end
    end

    def on_close(e)
      info "Closing code: #{e.code}: #{e}"
    end

    def listen_trades(markets_list=nil)
      info "Connecting to websocket: #{@ws_url}"

      @ws.on(:open) do |_e|
        on_open_trades(markets_list)
      end

      @ws.on(:message) do |e|
        msg = JSON.parse(e.data)
        new_trade(msg) if msg.is_a?(Array)
      end

      @ws.on(:close) do |e|
        on_close(e)
      end
    end

    #
    # PRIVATE METHODS
    #
    def create_order(order)
      params = {
        pair:      order.market,
        type:      order.side.to_s,
        volume:    "%f" % order.amount,
        price:     "%f" % order.price,
        ordertype: order.type.to_s,
      }

      post_private("AddOrder", params)
    end

    def stop_order(order)
      post_private("CancelOrder", txid: order.id)
    end

    def get_balances
      post_private("Balance").body["result"].map do |b|
        {
          "currency" => b.first,
          "free"     => 0,
          "locked"   => 0,
          "total"    => b.last.to_d,
        }
      end
    end

    def get_deposit_address(currency)
      method = post_private("DepositMethods", asset: currency).body["result"]&.first
      return "" if method.nil? || method["gen-address"] != true

      result = post_private("DepositAddresses", asset: currency, method: method["method"]).body["result"]
      {
        "address" => result&.map {|d| "%s (exp %s)" % [d["address"], d["expiretm"]] }&.join("\n            ")
      }
    end

    def fetch_openorders(market=nil)
      orders = []
      post_private("OpenOrders").body["result"]["open"].each do |id, o|
        descr = o["descr"]
        next unless descr
        next if market && market != descr["pair"]

        orders << ::Arke::Order.new(descr["pair"], descr["price"].to_d, o["vol"].to_d, descr["type"].to_sym, descr["ordertype"].to_sym, id)
      end
      orders
    end

    def post_private(method, opts={})
      raise "API key no configured" if @api_key.to_s.empty? || @api_secret.to_s.empty?

      url = "/0/private/%s" % [method]
      nonce = opts["nonce"] = generate_nonce()
      params = opts.map {|param| param.join("=") }.join("&")

      @rest_conn.post do |req|
        req.url(url)
        req.headers = {
          "api-key"      => @api_key,
          "api-sign"     => authenticate(auth_url(method, nonce, params)),
          "content-type" => "application/x-www-form-urlencoded"
        }
        req.body = params
      end
    end

    def generate_nonce
      (Time.now.to_f * 1_000_000).to_i
    end

    def auth_url(method, nonce, params)
      data = "#{nonce}#{params}"
      "/0/private/%s%s" % [method, Digest::SHA256.digest(data)]
    end

    def authenticate(url)
      hmac = OpenSSL::HMAC.digest("sha512", Base64.decode64(@api_secret), url)
      Base64.strict_encode64(hmac)
    end
  end
end
