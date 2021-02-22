# frozen_string_literal: true

module Arke::Exchange
  class Valr < Base
    attr_reader :orderbook

    def initialize(opts)
      super
      opts["host"] ||= "api.valr.com"

      @connection = Faraday.new(url: "https://#{opts['host']}") do |builder|
        builder.response :json
        builder.response :logger if opts["debug"]
        builder.adapter(@adapter)
      end
    end

    #
    # PUBLIC ENDPOINTS
    #

    def currencies
      @connection.get("/v1/public/currencies").body
    end

    def markets
      @connection.get("/v1/public/pairs").body
    end

    def market_config(market)
      market_infos = markets.select {|m| m["symbol"]&.upcase == market.upcase }.first
      raise "Market #{market} not found" unless market_infos

      {
        "id"               => market_infos.fetch("symbol"),
        "base_unit"        => market_infos.fetch("baseCurrency"),
        "quote_unit"       => market_infos.fetch("quoteCurrency"),
        "min_amount"       => market_infos.fetch("minBaseAmount").to_d,
        "amount_precision" => market_infos.fetch("baseDecimalPlaces").to_i,
        "price_precision"  => value_precision(market_infos["tickSize"].to_d)
      }
    end

    def build_order(data, side, market)
      Arke::Order.new(
        market,
        data["price"].to_f,
        data["quantity"].to_f,
        side
      )
    end

    def update_orderbook(market)
      orderbook = Arke::Orderbook::Orderbook.new(market)
      snapshot = @connection.get("/v1/public/#{market.upcase}/orderbook").body
      Array(snapshot["Bids"]).each do |order|
        orderbook.update(
          build_order(order, :buy, market)
        )
      end
      Array(snapshot["Asks"]).each do |order|
        orderbook.update(
          build_order(order, :sell, market)
        )
      end
      orderbook
    end

    #
    # AUTHENTICATED ENDPOINTS
    #

    def get_deposit_address(currency)
      authenticated_get("/v1/wallet/crypto/#{currency.upcase}/deposit/address").body
    end

    def get_balances
      response = authenticated_get("/v1/account/balances")
      raise response.body.to_s if response.status != 200

      response.body.map do |data|
        {
          "currency" => data["currency"],
          "free"     => data["available"].to_f,
          "locked"   => data["reserved"].to_f,
          "total"    => data["total"].to_f,
        }
      end
    end

    def fetch_openorders(market=nil)
      orders = []
      authenticated_get("/v1/orders/open").body&.each do |o|
        if market.nil? || market.upcase == o["currencyPair"].upcase
          order = Arke::Order.new(o["currencyPair"].upcase, o["price"].to_f, o["remainingQuantity"].to_f, o["side"].to_sym)
          order.id = o["orderId"]
          orders << order
        end
      end
      orders
    end

    def create_order(order)
      params = if order.type == "market"
                 {
                   pair:     order.market.upcase,
                   side:       order.side.to_s.upcase,
                   baseAmount: "%f" % order.amount
                 }
               else
                 {
                   pair:   order.market.upcase,
                   side:     order.side.to_s.upcase,
                   quantity: "%f" % order.amount,
                   price:    "%f" % order.price,
                 }
               end
      if order.type == "post_only"
        params[:postOnly] = true
        order.type == "limit"
      end
      response = authenticated_post("/v1/orders/#{order.type}", params: params)

      if response.status >= 300
        Arke::Log.warn "ACCOUNT:#{id} Failed to create order #{order} status:#{response.status}(#{response.reason_phrase}) body:#{response.body}"
      end

      order.id = response.env.body["id"] if response.env.body["id"]
      order
    end

    def stop_order(order)
      params = {
        "orderId": order.id,
        "pair":    order.market.upcase
      }
      authenticated_delete("/v1/orders/order", params: params)
    end

    def authenticated_get(path)
      raise "InvalidAuthKeyError" unless valid_key?

      nonce = new_nonce()
      @connection.get(
        path, {},
        "Accept"           => "application/json",
        "X-VALR-TIMESTAMP" => nonce,
        "X-VALR-SIGNATURE" => sign(nonce, "GET", path, ""),
        "X-VALR-API-KEY"   => @api_key
      )
    end

    def authenticated_post(path, options={})
      authenticated_method(path, :post, options)
    end

    def authenticated_delete(path, options={})
      authenticated_method(path, :delete, options)
    end

    def authenticated_method(path, method, options={})
      raise "InvalidAuthKeyError" unless valid_key?

      body = (options[:params] || {}).to_json
      nonce = new_nonce()

      @connection.send(method, path) do |req|
        req.body = body
        req.headers["Accept"] = "application/json"
        req.headers["X-VALR-TIMESTAMP"] = nonce
        req.headers["X-VALR-SIGNATURE"] = sign(nonce, method.to_s, path, body)
        req.headers["X-VALR-API-KEY"] = @api_key
      end
    end

    def new_nonce
      (Time.now.to_f * 1000).floor.to_s
    end

    def sign(nonce, verb, path, body)
      OpenSSL::HMAC.hexdigest("sha512", @secret, [nonce, verb.upcase, path, body].join)
    end
  end
end
