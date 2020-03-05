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
      @finex_route = config["finex_route"] || "finex"
      @finex = config["finex"] == true
      @ws_base_url = config["ws"] ||= "wss://%s" % [URI.parse(config["host"]).hostname]

      @connection = Faraday.new(url: "#{config["host"]}/api/v2") do |builder|
        builder.response :json
        builder.response :logger if @debug
        builder.adapter(@adapter)
        builder.ssl[:verify] = config["verify_ssl"] unless config["verify_ssl"].nil?
      end
      apply_flags(FORCE_MARKET_LOWERCASE)
      @books = {}
    end

    def ws_connect(ws_id)
      @ws_url = case ws_id
        when :public then "%s/api/v2/%s/public/?stream=global.tickers" % [@ws_base_url, @ranger_route]
        when :private then "%s/api/v2/%s/private/?stream=order&stream=trade" % [@ws_base_url, @ranger_route]
        end

      if flag?(LISTEN_PUBLIC_ORDERBOOK) && !@markets_to_listen.empty?
        @ws_url += "&" + @markets_to_listen.map { |id| "#{id}.ob-inc" }.join("&")
      end

      Fiber.new do
        EM::Synchrony.add_periodic_timer(53) do
          ws_write_message(ws_id, "ping")
        end
      end.resume

      super(ws_id)
    end

    # Ping the api
    def ping
      @connection.get "/#{barong_route}/identity/ping"
    end

    def cancel_all_orders(market)
      post(
        "#{@peatio_route}/market/orders/cancel",
        market: market.downcase,
      )
    end

    # Takes +order+ (+Arke::Order+ instance)
    # * creates +order+ via RestApi
    def create_order(order)
      raise "ACCOUNT:#{id} amount_s is nil" if order.amount_s.nil?
      raise "ACCOUNT:#{id} price_s is nil" if order.price_s.nil? && order.type == "limit"

      params = @finex ? {
        market:   order.market.downcase,
        side:     order.side.to_s,
        amount:   order.amount_s,
        price:    order.price_s,
        type: order.type,
      } : {
        market:   order.market.downcase,
        side:     order.side.to_s,
        volume:   order.amount_s,
        price:    order.price_s,
        ord_type: order.type,
      }
      params.delete(:price) if order.type == "market"
      response = post("#{@finex ? @finex_route : @peatio_route}/market/orders", params)

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
      response = post("#{@finex ? @finex_route : @peatio_route}/market/orders/#{order.id}/cancel")
      return unless response.body&.is_a?(Hash)
      raise response.body["errors"].to_s if response.body["errors"]
      return unless %w[cancel rejected done].include?(response.body["state"])

      logger.warn { "ACCOUNT:#{id} order #{order.id} was #{response.body["state"]}" }
      notify_deleted_order(order)
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

    def create_or_update_orderbook(orderbook, snapshot)
      (snapshot["bids"] || []).each do |price, amount|
        amount = amount.to_d
        if amount == 0
          orderbook[:buy].delete(price.to_d)
        else
          orderbook.update_amount(:buy, price.to_d, amount)
        end
      end
      (snapshot["asks"] || []).each do |price, amount|
        amount = amount.to_d
        if amount == 0
          orderbook[:sell].delete(price.to_d)
        else
          orderbook.update_amount(:sell, price.to_d, amount)
        end
      end
      orderbook
    end

    def update_orderbook(market)
      return @books[market][:book] if @books[market]
      limit = @opts["limit"] || 1000
      snapshot = @connection.get("#{@peatio_route}/public/markets/#{market.downcase}/depth", limit: limit).body
      create_or_update_orderbook(Arke::Orderbook::Orderbook.new(market), snapshot)
    end

    def get_market_infos(market)
      @market_infos ||= @connection.get("#{@peatio_route}/public/markets").body
      infos = @market_infos.select { |m| m["id"]&.downcase == market.downcase }.first
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
    def post(path, params = nil)
      logger.info { "ACCOUNT:#{id} POST: #{path} PARAMS: #{params}" } if @debug
      response = @connection.post do |req|
        req.headers = generate_headers
        req.url path
        req.body = params.to_json
      end
      response
    end

    def get(path, params = nil)
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

    def ws_read_public_message(msg)
      msg.each do |key, content|
        case key
        when /([^\.]+)\.ob-snap/
          @books[$1] = {
            book: create_or_update_orderbook(Arke::Orderbook::Orderbook.new($1), content),
            sequence: content["sequence"],
          }
        when /([^\.]+)\.ob-inc/
          return logger.error { "Received a book increment before snapshot on market #{$1}" } if @books[$1].nil?
          if content["sequence"] != @books[$1][:sequence] + 1
            logger.error { "Sequence out of order (previous: #{@books[$1][:sequence]} current:#{content["sequence"]}, reconnecting websocket..." }
            return @ws.close
          end
          bids = content["bids"]
          asks = content["asks"]
          create_or_update_orderbook(@books[$1][:book], { "bids" => [bids] }) if bids && !bids.empty?
          create_or_update_orderbook(@books[$1][:book], { "asks" => [asks] }) if asks && !asks.empty?
          @books[$1][:sequence] = content["sequence"]
        end
      end
    end

    def ws_read_private_message(msg)
      if msg["trade"]
        trd = msg["trade"]
        logger.debug { "ACCOUNT:#{id} trade received: #{trd}" }

        if trd["order_id"]
          amount = trd["amount"].to_f
          side = trd["side"].to_sym
          notify_private_trade(Arke::Trade.new(trd["id"], trd["market"].upcase, side, amount, trd["price"].to_f, trd["total"], trd["order_id"]), true)
        else
          amount = trd["volume"].to_f
          notify_private_trade(Arke::Trade.new(trd["id"], trd["market"].upcase, :buy, amount, trd["price"].to_f, trd["total"], trd["bid_id"]), false)
          notify_private_trade(Arke::Trade.new(trd["id"], trd["market"].upcase, :sell, amount, trd["price"].to_f, trd["total"], trd["ask_id"]), false)
        end
        return
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
        return
      end

      ws_read_public_message(msg)
    end
  end
end
