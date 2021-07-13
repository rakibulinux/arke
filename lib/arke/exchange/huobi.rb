# frozen_string_literal: true

module Arke::Exchange
  class Huobi < Base
    include Arke::Helpers::Precision
    attr_reader :orderbook, :ts_pattern

    def initialize(opts)
      super

      @ts_pattern = opts["ts_pattern"] || "%Y-%m-%dT%H:%M:%S"
      @host = opts["host"] || "api.huobi.pro"
      @ws_url = "wss://#{@host}/ws"
      @connection = Faraday.new(url: "https://#{@host}") do |builder|
        builder.response :logger if opts["debug"]
        builder.response :json
        builder.adapter(@adapter)
      end
      apply_flags(FORCE_MARKET_LOWERCASE)
      set_account unless @secret.to_s.empty?
    end

    def update_orderbook(market)
      orderbook = Arke::Orderbook::Orderbook.new(market)
      snapshot = @connection.get("/market/depth?symbol=#{market.downcase}&type=step0").body
      Array(snapshot["tick"]["bids"]).each do |order|
        orderbook.update(
          build_order(order, :buy)
        )
      end
      Array(snapshot["tick"]["asks"]).each do |order|
        orderbook.update(
          build_order(order, :sell)
        )
      end
      orderbook
    end

    def set_account
      path = "/v1/account/accounts"
      @account_id = authenticated_request(path, "GET").body["data"].first["id"]
    end

    def get_balances
      set_account
      path = "/v1/account/accounts/#{@account_id}/balance"
      accounts = authenticated_request(path, "GET").body["data"]["list"]

      balances = accounts.select {|a| a["type"] == "trade" }.map do |a|
        {
          "currency" => a["currency"].upcase,
          "free"     => a["balance"].to_f,
          "locked"   => 0.0,
          "total"    => a["balance"].to_f,
        }
      end
      accounts.select {|a| a["type"] == "frozen" }.map do |a|
        balance = balances.find {|b| b["currency"] == a["currency"].upcase }
        upd = {
          "locked" => a["balance"].to_f,
          "total"  => balance["free"].to_f + a["balance"].to_f
        }
        balance.update(upd)
      end
      balances
    end

    def create_order(order)
      raise "ACCOUNT:#{id} amount_s is nil" if order.amount_s.nil?
      raise "ACCOUNT:#{id} price_s is nil" if order.price_s.nil? && order.type == "limit"

      if order.type == "market"
        type = "market"
        if order.side == "buy"
          price_precision = market_config(order.market)["price_precision"]
          amount = apply_precision(order.amount * order.price, price_precision)
          amount = "%0.#{price_precision.to_i}f" % amount
        else
          amount = order.amount_s
        end
      else
        type = "limit"
        amount = order.amount_s
      end

      params = {
        "account-id": @account_id,
        "symbol":     order.market.downcase,
        "type":       "#{order.side}-#{type}",
        "amount":     amount,
      }
      params["price"] = order.price_s if type == "limit"
      authenticated_request("/v1/order/orders/place", "POST", params)
    end

    def stop_order(order)
      raise "Trying to cancel an order without id #{order}" if order.id.nil? || order.id == 0

      authenticated_request("/v1/order/orders/#{order.id}/submitcancel", "POST")
    end

    def fetch_openorders(market)
      path = "/v1/order/openOrders"
      authenticated_request(path, "GET").body["data"].map do |o|
        remaining_amount = o["amount"].to_f - o["filled-amount"].to_f
        # The order type, possible values are: buy-market, sell-market, buy-limit, sell-limit, buy-ioc, sell-ioc, buy-limit-maker, sell-limit-maker
        type = o["type"].split("-").first.to_sym
        next unless o["symbol"].downcase == market.downcase

        order = Arke::Order.new(o["symbol"], o["price"].to_f, remaining_amount, type)
        order.id = o["id"]
        order
      end
    end

    def symbols
      @symbols ||= get("/v1/common/symbols").body["data"]
    end

    def market_config(market)
      market_infos = symbols.find {|s| s["symbol"] == market }
      raise "Symbol #{market} not found" unless market_infos

      {
        "id"               => market_infos.fetch("symbol"),
        "base_unit"        => market_infos["base-currency"],
        "quote_unit"       => market_infos["quote-currency"],
        "min_price"        => nil,
        "max_price"        => nil,
        "min_amount"       => market_infos["min-order-amt"],
        "max_amount"       => market_infos["max-order-amt"],
        "amount_precision" => market_infos["amount-precision"],
        "price_precision"  => market_infos["price-precision"],
        "min_order_size"   => market_infos["min-order-value"]
      }
    end

    def ws_connect(ws_id)
      super(ws_id)

      @ws.on(:open) do |_e|
        if flag?(LISTEN_PUBLIC_TRADES)
          @markets_to_listen.each do |market|
            subscribe_trades(market, ws_id)
          end
        end

        Fiber.new do
          EM::Synchrony.add_periodic_timer(5) do
            ws_write_message(ws_id, JSON.dump("ping" => Time.now.to_i))
          end
        end.resume
      end
    end

    def subscribe_trades(market, ws_id)
      sub = {
        "sub" => "market.#{market}.trade.detail",
      }
      EM.next_tick { ws_write_message(ws_id, JSON.generate(sub)) }
    end

    def ws_read_message(ws_id, msg)
      data = Zlib::GzipReader.new(StringIO.new(msg.data.map(&:chr).join)).read
      object = JSON.parse(data)
      case ws_id
      when :public
        ws_read_public_message(object)
      when :private
        ws_read_private_message(object)
      else
        logger.error { "ACCOUNT:#{id} Unexpected websocket id #{ws_id} websocket message: #{data}" }
      end
    end

    def ws_read_public_message(msg)
      if msg["op"] == "ping"
        ws_write_message(:public, JSON.dump("op" => "pong", "ts" => msg["ts"]))
        return
      end

      if msg["ch"] =~ /market\.([^.]+)\.trade\.detail/
        parse_trade(msg, $1)
      end
    end

    def parse_trade(msg, market)
      msg["tick"]["data"].each do |trd|
        notify_public_trade ::Arke::PublicTrade.new(
          trd["tradeId"],
          market,
          "huobi",
          trd["direction"].to_sym,
          trd["amount"].to_d,
          trd["price"].to_d,
          trd["amount"].to_d * trd["price"].to_d,
          trd["ts"]
        )
      end
    end

    def build_order(data, side)
      Arke::Order.new(
        @market,
        data[0].to_f,
        data[1].to_f,
        side
      )
    end

    def authenticated_request(path, method, params={})
      h = {
        AccessKeyId:      @api_key,
        SignatureMethod:  "HmacSHA256",
        SignatureVersion: 2,
        Timestamp:        Time.now.getutc.strftime(ts_pattern)
      }
      h = h.merge(params) if method == "GET"
      data = "#{method}\n#{@host}\n#{path}\n#{Rack::Utils.build_query(hash_sort(h))}"
      h["Signature"] = sign(data)
      url = "https://#{@host}#{path}?#{Rack::Utils.build_query(h)}"

      method == "GET" ? get(url) : post(url, params)
    end

    def get(url)
      @connection.get do |req|
        req.url url
        req.headers["Content-Type"] = "application/json"
        req.headers["Accept"] = "application/json"
      end
    end

    def post(url, params)
      @connection.post do |req|
        req.url url
        req.body = params.to_json
        req.headers["Content-Type"] = "application/json"
        req.headers["Accept"] = "application/json"
      end
    end

    def sign(data)
      Base64.encode64(OpenSSL::HMAC.digest("sha256", @secret, data)).gsub("\n", "")
    end

    def hash_sort(ha)
      Hash[ha.sort_by {|key, _val| key }]
    end
  end
end
