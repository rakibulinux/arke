# frozen_string_literal: true

module Arke::Exchange
  class Rubykube < Base
    # Takes config (hash), strategy(+Arke::Strategy+ instance)
    # * +strategy+ is setted in +super+
    # * creates @connection for RestApi
    attr_accessor :orderbook

    def initialize(config)
      super
      @peatio_route = config["peatio_route"] || "peatio"
      @barong_route = config["barong_route"] || "barong"
      @ranger_route = config["ranger_route"] || "ranger"
      @ws_url = "#{config['ws']}/api/v2/#{@ranger_route}/private/?stream=order&stream=trade"
      @connection = Faraday.new(url: "#{config['host']}/api/v2") do |builder|
        builder.response :json
        builder.response :logger if @debug
        builder.adapter(@adapter)
        builder.ssl[:verify] = config["verify_ssl"] unless config["verify_ssl"].nil?
      end
      apply_flags(FORCE_MARKET_LOWERCASE)
    end

    def ws_connect_private
      ws_connect(:private)
      Fiber.new do
        EM::Synchrony.add_periodic_timer(290) do
          ws_write_message(:private, "ping")
        end
      end.resume
    end

    # Ping the api
    def ping
      @connection.get "/#{barong_route}/identity/ping"
    end

    def cancel_all_orders(market)
      post(
        "#{@peatio_route}/market/orders/cancel",
        market: market.downcase
      )
    end

    # Takes +order+ (+Arke::Order+ instance)
    # * creates +order+ via RestApi
    def create_order(order)
      raise "ACCOUNT:#{id} amount_s is nil" if order.amount_s.nil?
      raise "ACCOUNT:#{id} price_s is nil" if order.price_s.nil? && order.type == "limit"

      params = {
        market:   order.market.downcase,
        side:     order.side.to_s,
        volume:   order.amount_s,
        price:    order.price_s,
        ord_type: order.type,
      }
      params.delete(:price) if order.type == "market"
      response = post("#{@peatio_route}/market/orders", params)

      if response.status >= 300
        logger.warn { "ACCOUNT:#{id} Failed to create order #{order} status:#{response.status}(#{response.reason_phrase}) body:#{response.body}" }
      end

      if order.type == "limit" && response.env.status == 201 && response.env.body["id"]
        order.id = response.env.body["id"]
      end
      order
    end

    # Takes +order+ (+Arke::Order+ instance)
    # * cancels +order+ via RestApi
    def stop_order(order)
      post("#{@peatio_route}/market/orders/#{order.id}/cancel")
    end

    def get_balances
      response = get("#{@peatio_route}/account/balances")
      raise response.body.to_s if response.status != 200

      response.body.map do |data|
        {
          "currency" => data["currency"],
          "free"     => data["balance"].to_f,
          "locked"   => data["locked"].to_f,
          "total"    => data["balance"].to_f + data["locked"].to_f,
        }
      end
    end

    def currencies
      get("#{@peatio_route}/public/currencies").body
    end

    def get_deposit_address(currency)
      get("#{@peatio_route}/account/deposit_address/#{currency}").body
    end

    def fetch_openorders(market)
      orders = []
      max_limit = 1000
      total = get("#{@peatio_route}/market/orders", market: market.downcase.to_s, limit: 1, page: 1, state: "wait").headers["Total"]
      (total.to_f / max_limit).ceil.times do |page|
        get("#{@peatio_route}/market/orders", market: market.downcase.to_s, limit: max_limit, page: page + 1, state: "wait").body&.each do |o|
          order = Arke::Order.new(o["market"].upcase, o["price"].to_f, o["remaining_volume"].to_f, o["side"].to_sym)
          order.id = o["id"]
          orders << order
        end
      end
      orders
    end

    def build_order(data, side, market)
      Arke::Order.new(
        market,
        data[0].to_f,
        data[1].to_f,
        side
      )
    end

    def update_orderbook(market)
      orderbook = Arke::Orderbook::Orderbook.new(market)
      limit = @opts["limit"] || 1000
      snapshot = @connection.get("#{@peatio_route}/public/markets/#{market.downcase}/depth", limit: limit).body
      Array(snapshot["bids"]).each do |order|
        orderbook.update(
          build_order(order, :buy, market)
        )
      end
      Array(snapshot["asks"]).each do |order|
        orderbook.update(
          build_order(order, :sell, market)
        )
      end
      orderbook
    end

    def get_market_infos(market)
      @market_infos ||= @connection.get("#{@peatio_route}/public/markets").body
      infos = @market_infos.select {|m| m["id"]&.downcase == market.downcase }.first
      raise "Market #{market} not found" unless infos

      infos
    end

    def market_config(market)
      market_infos = get_market_infos(market)
      base_unit = market_infos["ask_unit"] || market_infos.fetch("base_unit")
      quote_unit = market_infos["bid_unit"] || market_infos.fetch("quote_unit")
      amount_precision = market_infos["ask_precision"] || market_infos.fetch("amount_precision")
      price_precision = market_infos["bid_precision"] || market_infos.fetch("price_precision")
      {
        "id"               => market_infos.fetch("id"),
        "base_unit"        => base_unit,
        "quote_unit"       => quote_unit,
        "min_price"        => (market_infos["min_price"] || market_infos["min_ask_price"])&.to_f,
        "max_price"        => (market_infos["max_price"] || market_infos["max_bid_price"])&.to_f,
        "min_amount"       => (market_infos["min_amount"] || market_infos["min_ask_amount"] || market_infos["min_bid_amount"])&.to_f,
        "amount_precision" => amount_precision,
        "price_precision"  => price_precision
      }
    end

    def generate_headers
      nonce = Time.now.to_i.to_s
      {
        "X-Auth-Apikey"    => @api_key,
        "X-Auth-Nonce"     => nonce,
        "X-Auth-Signature" => OpenSSL::HMAC.hexdigest("SHA256", @secret, nonce + @api_key),
        "Content-Type"     => "application/json",
      }
    end

    private

    # Helper method to perform post requests
    # * takes +conn+ - faraday connection
    # * takes +path+ - request url
    # * takes +params+ - body for +POST+ request
    def post(path, params=nil)
      logger.info { "ACCOUNT:#{id} POST: #{path} PARAMS: #{params}" } if @debug
      response = @connection.post do |req|
        req.headers = generate_headers
        req.url path
        req.body = params.to_json
      end
      response
    end

    def get(path, params=nil)
      response = @connection.get do |req|
        req.headers = generate_headers
        req.url path, params
      end
      response
    end

    # Helper method, generates headers to authenticate with +api_key+

    def side_from_kind(kind)
      kind == "bid" ? :buy : :sell
    end

    def ws_read_private_message(msg)
      if msg["trade"]
        trd = msg["trade"]
        notify_private_trade(Arke::Trade.new(trd["id"], trd["market"].upcase, :buy, trd["volume"].to_f, trd["price"].to_f, trd["bid_id"]))
        notify_private_trade(Arke::Trade.new(trd["id"], trd["market"].upcase, :sell, trd["volume"].to_f, trd["price"].to_f, trd["ask_id"]))
      end

      if msg["order"]
        ord = msg["order"]
        side = side_from_kind(ord["kind"])
        order = Arke::Order.new(ord["market"].upcase, ord["price"].to_f, ord["remaining_volume"].to_f, side)
        order.id = ord["id"]
        case ord["state"]
        when "wait"
          notify_created_order(order)
        when "cancel", "done"
          notify_deleted_order(order)
        end
      end
    end
  end
end
