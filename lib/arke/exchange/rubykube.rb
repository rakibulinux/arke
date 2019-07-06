module Arke::Exchange
  class Rubykube < Base
    # Takes config (hash), strategy(+Arke::Strategy+ instance)
    # * +strategy+ is setted in +super+
    # * creates @connection for RestApi
    attr_accessor :orderbook

    def initialize(config)
      super
      @ws_url = "#{config["ws"]}/api/v2/ranger/private/?stream=order&stream=trade"
      @connection = Faraday.new(:url => "#{config["host"]}/api/v2") do |builder|
        builder.response :json
        builder.response :logger if opts["debug"]
        builder.adapter(@adapter)
        builder.ssl[:verify] = config["verify_ssl"] unless config["verify_ssl"].nil?
      end
    end

    def start
      fetch_openorders

      @ws = Faye::WebSocket::Client.new(@ws_url, [], { :headers => generate_headers })

      @ws.on(:open) do |e|
        p [:open]
      end

      @ws.on(:message) do |e|
        on_message(e)
      end

      @ws.on(:close) do |e|
        on_close(e)
        @ws = nil
      end
    end

    # Ping the api
    def ping
      @connection.get "/barong/identity/ping"
    end

    def cancel_all_orders
      response = post(
        'peatio/market/orders/cancel',
        { market: @market.downcase }
      )
      @open_orders.clear if response.env.status == 201
    end

    # Takes +order+ (+Arke::Order+ instance)
    # * creates +order+ via RestApi
    def create_order(order)
      params = {
        market: @market.downcase,
        side: order.side.to_s,
        volume: order.amount,
        ord_type: order.type,
        price: order.price,
      }
      params.delete(:price) if order.type == "market"
      response = post("peatio/market/orders", params)
      if order.type == "limit" && response.env.status == 201 && response.env.body["id"]
        @open_orders.add_order(order, response.env.body["id"])
      end
      response
    end

    # Takes +order+ (+Arke::Order+ instance)
    # * cancels +order+ via RestApi
    def stop_order(id)
      response = post(
        "peatio/market/orders/#{id}/cancel"
      )
      @open_orders.remove_order(id)

      response
    end

    def get_balances
      response = get("peatio/account/balances")
      raise "#{response.body}" if response.status != 200
      response.body.map do |data|
        {
          "currency" => data["currency"],
          "free" => data["balance"].to_f,
          "locked" => data["locked"].to_f,
          "total" => data["balance"].to_f + data["locked"].to_f,
        }
      end
    end

    def currencies
      get("peatio/public/currencies").body
    end

    def get_deposit_address(currency)
      get("peatio/account/deposit_address/#{currency}").body
    end

    def fetch_openorders
      max_limit = 1000
      total = get("peatio/market/orders", { market: "#{@market.downcase}", limit: 1, page: 1, state: "wait" }).headers["Total"]
      (total.to_f / max_limit.to_f).ceil.times do |page|
        response = get("peatio/market/orders", { market: "#{@market.downcase}", limit: max_limit, page: page + 1, state: "wait" }).body.each do |o|
          order = Arke::Order.new(o["market"].upcase, o["price"].to_f, o["remaining_volume"].to_f, o["side"].to_sym)
          @open_orders.add_order(order, o["id"])
        end
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

    def update_orderbook
      orderbook = Arke::Orderbook::Orderbook.new(@market)
      limit = @opts["limit"] || 1000
      snapshot = @connection.get("peatio/public/markets/#{@market.downcase}/depth", { limit: limit }).body
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

    def get_market_infos
      response = @connection.get("peatio/public/markets").body
      infos = response.select { |m| m['id'] == @market.downcase }.first
      raise "Market #{@market} not found" unless infos
      infos
    end

    private

    # Helper method to perform post requests
    # * takes +conn+ - faraday connection
    # * takes +path+ - request url
    # * takes +params+ - body for +POST+ request
    def post(path, params = nil)
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
    def generate_headers
      nonce = Time.now.to_i.to_s
      {
        "X-Auth-Apikey" => @api_key,
        "X-Auth-Nonce" => nonce,
        "X-Auth-Signature" => OpenSSL::HMAC.hexdigest("SHA256", @secret, nonce + @api_key),
        "Content-Type" => "application/json",
      }
    end

    def side_from_kind(kind)
      kind == "bid" ? :buy : :sell
    end

    def process_trade(trade, order)
      notify_trade(trade, order)
      if order.amount == trade.volume
        @open_orders.remove_order(trade.order_id)
      end
    end

    def process_message(msg)
      # Arke::Log.debug "#{self.class}#process_message: #{msg}"
      if trd = msg["trade"]
        if order = @open_orders.get_by_id(:buy, trd["bid_id"])
          trade = Arke::Trade.new(trd["market"], :buy, trd["volume"].to_f, trd["price"].to_f, trd["bid_id"])
          process_trade(trade, order)
        end

        if order = @open_orders.get_by_id(:sell, trd["ask_id"])
          trade = Arke::Trade.new(trd["market"], :sell, trd["volume"].to_f, trd["price"].to_f, trd["ask_id"])
          process_trade(trade, order)
        end
      end

      if msg["order"] && msg["order"]["market"] == @market.downcase
        ord = msg["order"]
        side = side_from_kind(ord["kind"])
        case ord["state"]
        when "wait"
          order = Arke::Order.new(ord["market"].upcase, ord["price"].to_f, ord["remaining_volume"].to_f, side)
          @open_orders.add_order(order, ord["id"])
        when "cancel"
          @open_orders.remove_order(ord["id"]) if @open_orders.exist?(side, ord["price"].to_f, ord["id"])
        end
      end
    end

    def on_message(e)
      msg = JSON.parse(e.data)
      process_message(msg)
    end

    def on_close(e)
      Arke::Log.info "Closing code: #{e.code} Reason: #{e.reason}"
    end
  end
end
