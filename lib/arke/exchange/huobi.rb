# frozen_string_literal: true

module Arke::Exchange
  class Huobi < Base
    attr_reader :orderbook, :ts_pattern

    def initialize(opts)
      super

      @ts_pattern = opts['ts_pattern'] || "%Y-%m-%dT%H:%M:%S"
      @connection = Faraday.new(url: "https://#{opts['host']}") do |builder|
        builder.response :logger if opts["debug"]
        builder.use FaradayMiddleware::ParseJson, content_type: /\bjson$/
        builder.adapter(@adapter)
      end
      set_account unless @secret.to_s.empty?
    end

    def start; end

    def update_orderbook(market)
      orderbook = Arke::Orderbook::Orderbook.new(market)
      snapshot = JSON.parse(@connection.get("/market/depth?symbol=#{market.downcase}&type=step0").body)
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
      order = {
        "account-id": @account_id,
        "symbol":     order.market.downcase,
        "type":       "#{order.side}-limit",
        "amount":     "%f" % order.amount,
        "price":      "%f" % order.price,
      }
      authenticated_request("/v1/order/orders/place", "POST", order)
    end

    def fetch_openorders(market)
      path = "/v1/order/openOrders"
      authenticated_request(path, "GET").body["data"].map do |o|
        remaining_amount = o["amount"].to_f - o["filled-amount"].to_f
        # The order type, possible values are: buy-market, sell-market, buy-limit, sell-limit, buy-ioc, sell-ioc, buy-limit-maker, sell-limit-maker
        type = o["type"].split("-").first.to_sym
        next unless o["symbol"].upcase == market.upcase

        order = Arke::Order.new(o["symbol"].upcase, o["price"].to_f, remaining_amount, type)
        order.id = o["id"]
        order
      end
    end

    def symbols
      get("/v1/common/symbols").body["data"]
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
      }
    end

    private

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
      data = "#{method}\napi.huobi.pro\n#{path}\n#{Rack::Utils.build_query(hash_sort(h))}"
      h["Signature"] = sign(data)
      url = "https://api.huobi.pro#{path}?#{Rack::Utils.build_query(h)}"

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
