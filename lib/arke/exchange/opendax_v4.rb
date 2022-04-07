# frozen_string_literal: true

module Arke::Exchange
  class OpendaxV4 < Base
    DEFAULT_TIMEOUT = 5

    # Websocket
    MSG_TYPE_REQUEST       = 1
    MSG_TYPE_RESPONSE      = 2
    MSG_TYPE_PUBLIC_EVENT  = 3
    MSG_TYPE_PRIVATE_EVENT = 4

    EVENT_BALANCE_UPDATE      = "bu"
    EVENT_ORDER_CREATE        = "on"
    EVENT_ORDER_CANCEL        = "oc"
    EVENT_ORDER_UPDATE        = "ou"
    EVENT_ORDER_REJECT        = "or"
    EVENT_TRADE               = "tr"
    EVENT_ORDERBOOK_INCREMENT = "obi"
    EVENT_ORDERBOOK_SNAPSHOT  = "obs"
    EVENT_SYSTEM              = "sys"

    METHOD_PING               = "ping"
    METHOD_SUBSCRIBE          = "subscribe"
    METHOD_LIST_ORDERS        = "list_orders"
    METHOD_CREATE_ORDER       = "create_order"
    METHOD_CANCEL_ORDER       = "cancel_order"
    METHOD_CANCEL_ALL         = "cancel_all"

    TOPIC_BALANCES            = "balances"
    TOPIC_ORDER               = "order"
    TOPIC_TRADE               = "trade"

    def initialize(config)
      super
      @ws_url = config["ws"] ||= "wss://%s/api/v1/finex/ws" % [URI.parse(config["host"]).hostname]
      @reqid = 0
      @req_ctx = {}
      @timeout = config["timeout"] || DEFAULT_TIMEOUT
      @markets = []
      @balances = nil
      @kong_key = config["kong_key"]
      @go_true_url = config["go_true_url"]
      @verify_ssl = config["verify_ssl"].nil? ? true : config["verify_ssl"]
      apply_flags(WS_PRIVATE)

      @connection = Faraday.new(url: @go_true_url) do |conn|
        conn.options.timeout = 10
        conn.response :json
        conn.response :logger if @debug
        conn.ssl[:verify] = config["verify_ssl"] unless config["verify_ssl"].nil?
        conn.adapter(@adapter)
      end

      fetch_markets unless ENV['RUBY_ENV'] == "test"
    end

    def ws_connect(ws_id)
      logger.info { "ACCOUNT:#{id} Websocket #{ws_id} connecting to #{@ws_url}" }
      fb = Fiber.current
      @ws = Faye::WebSocket::Client.new(@ws_url, [], {
        headers: generate_headers(ws_id),
        tls: {
          verify_peer: @verify_ssl,
        }
      })

      @ws.on(:open) do |_e|
        @ws_connected = true
        subscribe_public if flag?(LISTEN_PUBLIC_ORDERBOOK) && !@markets_to_listen.empty?

        Fiber.new do
          EM::Synchrony.add_periodic_timer(53) do
            msg = JSON.dump([MSG_TYPE_REQUEST, reqid, METHOD_PING, []])
            ws_write_message(ws_id, msg)
          end
        end.resume

        logger.info { "ACCOUNT:#{id} Websocket #{ws_id} connected" }
        fb.resume
      end

      @ws.on(:message) do |msg|
        ws_read_message(ws_id, msg)
      end

      @ws.on(:close) do |e|
        reason = e.reason.empty? ? (@ws.instance_variable_get(:@event_buffers)||{})["error"]&.map(&:message)&.join("\n") : e.reason
        logger.error "ACCOUNT:#{id} Websocket #{ws_id} disconnected: #{e.code} Reason: #{reason}"
        @ws = nil
        Fiber.new do
          EM::Synchrony.sleep(WEBSOCKET_CONNECTION_RETRY_DELAY)
          ws_connect(ws_id)
        end.resume
        fb.resume if fb.alive? && !@ws_connected
        @ws_connected = false
      end
      Fiber.yield
    end

    def subscribe_public
      streams = []
      @markets_to_listen.each do |id|
        streams << "#{id}.ob-inc"
      end

      EM.next_tick do
        ws_write_message(:public, JSON.dump([MSG_TYPE_REQUEST, reqid, METHOD_SUBSCRIBE, ["public", streams]]))
      end
    end

    def generate_headers(ws_id)
      case ws_id
      when :private
        jwt_token = generate_jwt()
        {
          "Authorization" => "Bearer " + jwt_token
        }
      else
        {}
      end
    end

    def ws_read_message(ws_id, msg)
      logger.debug { "ACCOUNT:#{id} received #{ws_id} websocket message: #{msg.data}" }

      msg = JSON.parse(msg.data)

      case msg.first
      when MSG_TYPE_RESPONSE
        _, rid, method, args = msg
        ws_handle_response(method, rid, args)

      when MSG_TYPE_PUBLIC_EVENT
        _, method, args = msg
        ws_handle_public_event(method, args)

      when MSG_TYPE_PRIVATE_EVENT
        _, method, args = msg
        ws_handle_private_event(method, args)
      else
        raise "Unexpected message type in message: #{msg.data}"
      end
    end

    def respond_to(rid, fiber)
      timer = EM::Timer.new(@timeout) do
        logger.error { "Request #{rid} timed out" }
        @req_ctx.delete(rid)
        fiber.resume
      end
      @req_ctx[rid] = [fiber, timer]
    end

    def cleanup(rid)
      _, timer = @req_ctx.delete(rid)
      timer.cancel
    end

    def ws_handle_response(method, rid, args)
      case method
      when METHOD_LIST_ORDERS
        f, = @req_ctx[rid]
        if f.nil?
          logger.error { "Unknown request with rid #{rid}" }
          return
        end
        cleanup(rid)
        f.resume(args.map {|o| parse_order(o) })
      when "error"
        logger.error { "Handle response error: #{args[0]}" }
      end
    end

    def ws_handle_public_event(method, args)
      case method
      when EVENT_ORDERBOOK_SNAPSHOT
        content = {}
        market = args[0]
        content["asks"] = args[3]
        content["bids"] = args[2]

        @books[market] = {
          book:     create_or_update_orderbook(Arke::Orderbook::Orderbook.new(market), content),
          sequence: args[1],
        }
      when EVENT_ORDERBOOK_INCREMENT
        market = args[0]

        if @books[market].nil?
          return logger.error { "Received a book increment before snapshot on market #{market}" }
        end

        sequence = args[1]
        if sequence != @books[market][:sequence] + 1
          logger.error { "Sequence out of order (previous: #{@books[market][:sequence]} current:#{sequence}, reconnecting websocket..." }
          return @ws.close
        end

        asks = args[2]
        bids = args[3]

        notify_orderbook_increment([id,  market, sequence, asks, bids])

        create_or_update_orderbook(@books[market][:book], {"bids" => bids}) if bids && !bids.empty?
        create_or_update_orderbook(@books[market][:book], {"asks" => asks}) if asks && !asks.empty?
        @books[market][:sequence] = sequence

      when "markets"
        @markets = args
        f, = @req_ctx["markets"]
        unless f.nil?
          cleanup("markets")
          f.resume
        end
      end
    end

    def parse_order(o)
      type = convert_from_type(o[5])
      Arke::Order.new(o[0], o[6].to_f, o[8].to_f, o[3].to_sym, type, o[2])
    end

    def ws_handle_private_event(method, args)
      case method
      when EVENT_BALANCE_UPDATE
        # Event example [4,"bu",[["tok","1000","0"],["usdt","999.99998","0"],["btc","999.9998","0"],["eth","1000","0"],["local","1000","0"]]]
        logger.debug { "ACCOUNT:#{id} balance update received: #{args}" }

        balances = args.map {|currency, total, locked|
          free = total.to_d - locked.to_d
          {
            "currency" => currency,
            "free"     => free,
            "locked"   => locked.to_d,
            "total"    => total.to_d,
          }
        }
        update_balances(balances)

        f, = @req_ctx["balances"]
        unless f.nil?
          cleanup("balances")
          f.resume
        end
      when EVENT_TRADE
        # Event example [4,"tr",["btcusdt",9,"0.1","0.1","0.01",23,"2f15ccd9-0708-43c8-9451-60bb98b620f1","sell","sell","0.00002","usdt",1639470508]]
        logger.debug { "ACCOUNT:#{id} trade received: #{args}" }

        side = args[7].to_sym
        notify_private_trade(Arke::Trade.new(args[1], args[0], side, args[3].to_f, args[2].to_f, args[4], args[5]), false)
      when EVENT_ORDER_CANCEL, EVENT_ORDER_UPDATE, EVENT_ORDER_REJECT, EVENT_ORDER_CREATE
        # Event example [4,"on",["btcusdt",18,"3b0474d7-6219-445b-a614-7208f9360135","buy","d","l","0.002","0","0","0.001","0.001",0,1639469280,"0.002","0.002"]]

        event = OpendaxV4.constants.find { |k| OpendaxV4.const_get(k) == method }
        logger.debug { "ACCOUNT:#{id} #{event.to_s}: #{args}"  }

        order = parse_order(args)
        case args[4]
        when "w"
          notify_created_order(order)
        when "d", "c"
          notify_deleted_order(order)
        end
      when EVENT_SYSTEM
        msg, uid = args
        if msg == "authenticated"
          @uid = uid
          subscribe_private
        end
      end
    end

    def get_balances
      if @balances.nil?
        respond_to("balances", Fiber.current)
        Fiber.yield
      end
      @balances
    end

    def update_orderbook(market)
      return @books[market][:book] if @books[market]
    end

    def subscribe_private
      streams = [TOPIC_BALANCES, TOPIC_ORDER, TOPIC_TRADE]
      ws_write_message(:private, JSON.dump([MSG_TYPE_REQUEST, reqid, METHOD_SUBSCRIBE, ["private", streams]]))
    end

    def create_order(order)
      # Request [1, 42, "create_order", ["btcusd", "m", "sell", "amount", "price"]]
      type = convert_type(order.type)
      order_params = [order.market.downcase, type, order.side.to_s, order.amount.to_f.to_s, order.price.to_f.to_s]
      ws_write_message(:private, JSON.dump([MSG_TYPE_REQUEST, reqid, METHOD_CREATE_ORDER, order_params]))

      order
    end

    def stop_order(order)
      # Request [1, 42, "cancel_order", [["btcusd", "bc8b9e47-ac5f-443c-ae7b-e4e9758df20b"]]
      order_params = [[order.market.downcase, order.id]]
      ws_write_message(:private, JSON.dump([MSG_TYPE_REQUEST, reqid, METHOD_CANCEL_ORDER, order_params]))

      order
    end

    def cancel_all_orders(market)
      # Request [1, 42, "cancel_all", []]
      ws_write_message(:private, JSON.dump([MSG_TYPE_REQUEST, reqid, METHOD_CANCEL_ALL, []]))
    end

    def fetch_openorders(market)
      # Request [1, 42, "list_orders", ["btcusdt", 0, 0, "wait"]]
      rid = reqid()
      respond_to(rid, Fiber.current)
      order_params = [market.downcase, 0, 0, "wait"]
      ws_write_message(:private, JSON.dump([MSG_TYPE_REQUEST, rid, METHOD_LIST_ORDERS, order_params]))
      Fiber.yield
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

    def fetch_markets
      EM.synchrony do
        respond_to("markets", Fiber.current)
        Fiber.new { ws_connect_public }.resume
        Fiber.yield
        EM.stop
      end
    end

    def market_config(market)
      market_response = @markets.select { |m| m[0] == market.downcase }.flatten
      raise "Market #{market} not found" if market_response.empty?

      {
        "id"               => market_response[0],
        "base_unit"        => market_response[2],
        "quote_unit"       => market_response[3],
        "min_price"        => market_response[8].to_f,
        "max_price"        => market_response[9].to_f,
        "min_amount"       => market_response[10].to_f,
        "amount_precision" => market_response[6].to_f,
        "price_precision"  => market_response[7].to_f,
      }
    end

    def reqid
      @reqid += 1
    end

    def generate_jwt
      raise "There is no api key" if @api_key.nil?

      key = Eth::Key.new priv: @api_key
      address = key.address

      response = post("/api/v1/auth/sign_challenge", {algorithm: 'ETH', key: address})
      raise response.body.to_s if response.status != 200

      token = response.body['challenge_token']
      hash = sign_eth_message(token)
      signature = generate_signature(hash)

      response = post("/api/v1/auth/asymmetric_login",{key: address, challenge_token_signature: signature})
      raise response.body.to_s if response.status != 200

      response.body['access_token']
    end

    private

    def convert_type(type)
      case type
      when "market"
        return "m"
      else
        return "l"
      end
    end

    def convert_from_type(type)
      case type
      when "l"
        return "limit"
      when "m"
        return "market"
      else
        return type
      end
    end

    # Helper method to perform post requests
    # * takes +conn+ - faraday connection
    # * takes +path+ - request url
    # * takes +params+ - body for +POST+ request
    def post(path, params=nil)
      response = @connection.post do |req|
        req.headers = generate_auth_headers
        req.url path
        req.body = params.to_json
      end
      response
    end

    # Helper method to generate headers
    def generate_auth_headers
      {
        "apikey"           => @kong_key,
        "Content-Type"     => "application/json",
      }
    end

    def generate_signature(hash)
      private_key = Arke::Ethereum::PrivateKey.new(@api_key)

      # Sigh hash with private key
      v, r, s = Arke::Ethereum::Secp256k1.recoverable_sign(hash, private_key.encode(:bin))
      # Form signature from R and S values
      raw_sig = Arke::Ethereum::Utils.zpad_int(r) + Arke::Ethereum::Utils.zpad_int(s)

      "0x" + raw_sig.unpack("H*")[0] + v.to_s(16)
    end

    def sign_eth_message(token)
      message = "\x19Ethereum Signed Message:\n#{token.length}#{token}"
      Arke::Ethereum::Utils.keccak256(message)
    end
  end
end
