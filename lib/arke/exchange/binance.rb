# frozen_string_literal: true

module Arke::Exchange
  class Binance < Base
    include Arke::Helpers::Precision

    attr_accessor :orderbook

    WS_ORDERBOOK_MIN_CACHE_SIZE = 200
    WS_ORDERBOOK_MAX_CACHE_SIZE = 500

    Error = Class.new(StandardError)
    ConnectionError = Class.new(Error)
    class ResponseError < Error
      def initialize(msg)
        super msg.to_s
      end
    end

    def initialize(config)
      super
      @host ||= "https://api.binance.com"

      @connection = Faraday.new(url: @host, request: {params_encoder: Arke::Helpers::FlatParamsEncoder}) do |conn|
        conn.options.timeout = 10
        conn.response :json
        conn.response :logger if @debug
        conn.ssl[:verify] = config["verify_ssl"] unless config["verify_ssl"].nil?
        # conn.adapter :net_http_persistent, pool_size: 5, idle_timeout: 20
        conn.adapter(@adapter)
      end

      @min_notional = {}
      @min_quantity = {}
      @amount_precision = {}
      # @ws_stream_ids = {}
    end

    def ws_connect(ws_id)
      raise "Unsupported websocket type #{ws_id}" unless ws_id == :public

      streams = []
      streams += @markets_to_listen.map {|market| "#{market.downcase}@aggTrade.b10" } if flag?(LISTEN_PUBLIC_TRADES)
      streams += @markets_to_listen.map {|market| "#{market.downcase}@depth" } if flag?(LISTEN_PUBLIC_ORDERBOOK)

      @ws_url = "wss://stream.binance.com:9443/stream?streams=#{streams.join('/')}"
      super(ws_id) unless streams.empty?

      if flag?(LISTEN_PUBLIC_ORDERBOOK)
        @ws.on(:open) do
          @markets_to_listen.each do |market|
            logger.info { "ACCOUNT:#{id} orderbook #{market} initializing" }
            Fiber.new { initialize_orderbook(market) }.resume
          end
        end
      end
    end

    #
    # how-to-manage-a-local-order-book-correctly
    #
    # https://github.com/binance/binance-spot-api-docs/blob/master/web-socket-streams.md#how-to-manage-a-local-order-book-correctly
    #
    # 1. Open a stream to wss://stream.binance.com:9443/ws/bnbbtc@depth.
    # 2. Buffer the events you receive from the stream.
    # 3. Get a depth snapshot from https://api.binance.com/api/v3/depth?symbol=BNBBTC&limit=1000 .
    # 4. Drop any event where u is <= lastUpdateId in the snapshot.
    # 5. The first processed event should have U <= lastUpdateId+1 AND u >= lastUpdateId+1.
    # 6. While listening to the stream, each new event's U should be equal to the previous event's u+1.
    # 7. The data in each event is the absolute quantity for a price level.
    # 8. If the quantity is 0, remove the price level.
    # 9. Receiving an event that removes a price level that is not in your local order book can happen and is normal.
    #

    def initialize_orderbook(market)
      @books[market] = {
        init: true,
        inc:  []
      }
      last_update_id, ob = fetch_orderbook(market)
      @books[market][:book] = ob
      @books[market][:init] = false
      @books[market][:inc].each do |data|
        next if data["u"] <= last_update_id

        handle_orderbook_update(data)
      end
      logger.info { "ACCOUNT:#{id} orderbook #{market} initialized" }
    end

    def handle_orderbook_update(data)
      market = data["s"]
      bids = data["b"]
      asks = data["a"]
      first_update_id = data["U"]
      last_update_id = data["u"]

      # 2. Buffer the events you receive from the stream.
      if @books[market][:init]
        @books[market][:inc] << data
        return
      end

      @books[market][:sequence] ||= first_update_id - 1

      if first_update_id != @books[market][:sequence] + 1
        logger.error { "Sequence out of order (previous: #{@books[market][:sequence]} current:#{first_update_id}, reconnecting websocket..." }
        @ws.close
        return @books.clear
      end

      bids.each do |order|
        @books[market][:book].update(
          build_order(order, :buy)
        )
      end
      asks.each do |order|
        @books[market][:book].update(
          build_order(order, :sell)
        )
      end
      remove_empty_orderbook(@books[market][:book])
      limit_orderbook(@books[market][:book], WS_ORDERBOOK_MIN_CACHE_SIZE, WS_ORDERBOOK_MAX_CACHE_SIZE)
      @books[market][:sequence] = last_update_id
    end


    def ws_read_public_message(msg)
      # # Ignore successfully subscribed message
      # return if msg.key?("id") && @ws_stream_ids.key?(msg["id"])

      d = msg["data"]
      case d["e"]
      # "m": true, Is the buyer the market maker?
      # in API we expose taker_type
      when "aggTrade", "trade"
        trade = ::Arke::PublicTrade.new
        trade.id = d["e"] == "aggTrade" ? d["a"] : d["t"]
        trade.market = d["s"]
        trade.exchange = "binance"
        trade.taker_type = d["m"] ? "sell" : "buy"
        trade.amount = d["q"].to_d
        trade.price = d["p"].to_d
        trade.total = trade.total
        trade.created_at = d["T"]
        notify_public_trade(trade)
      when "depthUpdate"
        handle_orderbook_update(d)
      else
        raise "Unsupported event type #{d['e']}"
      end
    end

    def remove_empty_orderbook(orderbook)
      orderbook.book.each do |_side, book|
        book.delete_if {|_, amount| amount.zero? }
      end
    end

    def limit_orderbook(orderbook, min=200, max=500)
      orderbook.book.each do |side, book|
        next unless book.keys.length > max

        orders = book.sort
        orders.reverse! if side == :buy
        orders.drop(min).each do |order|
          book.delete(order[0])
        end
      end
    end

    def build_order(data, side)
      Arke::Order.new(
        @market,
        data[0].to_d,
        data[1].to_d,
        side
      )
    end

    def new_trade(data)
      taker_type = data["b"] > data["a"] ? :buy : :sell
      market = data["s"]
      pm_id = @platform_markets[market]

      trade = Trade.new(
        price:              data["p"],
        amount:             data["q"],
        platform_market_id: pm_id,
        taker_type:         taker_type
      )
      @opts[:on_trade]&.call(trade, market)
    end

    def update_orderbook(market)
      return @books[market][:book] if @books[market] && !@books[market][:init]

      _, ob = fetch_orderbook(market)
      ob
    end

    def fetch_orderbook(market)
      orderbook = Arke::Orderbook::Orderbook.new(market)
      limit = @opts["limit"] || 1000
      snapshot = @connection.get("/api/v3/depth", symbol: market, limit: limit).body

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
      [snapshot["lastUpdateId"], orderbook]
    end

    def get_amount(order)
      min_notional = @min_notional[order.market] ||= get_min_notional(order.market)
      amount_precision = @amount_precision[order.market] ||= get_amount_precision(order.market)
      notional = order.price * order.amount
      amount = if order.price.to_d.zero? or notional > min_notional
                 order.amount
               else
                 (min_notional / order.price).ceil(amount_precision)
               end
      "%0.#{amount_precision.to_i}f" % amount
    end

    def create_order(order)
      amount = get_amount(order)
      return if amount.to_f.zero?
      raise "ACCOUNT:#{id} price_s is nil" if order.price_s.nil? && order.type == "limit"

      raw_order = {
        symbol:   order.market,
        side:     order.side.upcase,
        quantity: "%f" % amount,
      }

      if order.type == "market"
        raw_order[:type] = "MARKET"
      else
        raw_order[:type] = "LIMIT"
        raw_order[:price] = order.price_s
        raw_order[:timeInForce] = "GTC"
      end
      logger.debug { "Binance order: #{raw_order}" }

      rest_api(:post, "/api/v3/order", raw_order)
    end

    def stop_order(order)
      raise "Trying to cancel an order without id #{order}" if order.id.nil? || order.id == 0

      rest_api(:delete, "/api/v3/order", {
        symbol:  order.market,
        orderId: order.id,
      })
    end

    def get_balances
      balances = rest_api(:get, "/api/v3/account")["balances"]
      balances.map do |data|
        {
          "currency" => data["asset"],
          "free"     => data["free"].to_f,
          "locked"   => data["locked"].to_f,
          "total"    => data["free"].to_f + data["locked"].to_f,
        }
      end
    end

    def fetch_openorders(market)
      rest_api(:get, "/api/v3/openOrders", symbol: market).map do |o|
        raise "Unexpected response: #{o} (check the market ID)" unless o.is_a?(Hash)

        remaining_volume = o["origQty"].to_f - o["executedQty"].to_f
        Arke::Order.new(
          o["symbol"],
          o["price"].to_f,
          remaining_volume,
          o["side"].downcase.to_sym,
          o["type"].downcase.to_sym,
          o["orderId"]
        )
      end
    end

    def get_amount_precision(market)
      min_quantity = @min_quantity[market] ||= get_min_quantity(market)
      value_precision(min_quantity)
    end

    def get_symbol_info(market)
      @exchange_info ||= @connection.get("/api/v3/exchangeInfo").body["symbols"]
      @exchange_info&.find {|s| s["symbol"] == market }
    end

    def get_symbol_filter(market, filter)
      info = get_symbol_info(market)
      raise "#{market} not found" unless info

      info["filters"].find {|f| f["filterType"] == filter }
    end

    def get_min_quantity(market)
      get_symbol_filter(market, "LOT_SIZE")["minQty"].to_f
    end

    def get_min_notional(market)
      get_symbol_filter(market, "MIN_NOTIONAL")["minNotional"].to_f
    end

    def market_config(market)
      info = get_symbol_info(market)
      raise "#{market} not found" unless info

      price_filter = get_symbol_filter(market, "PRICE_FILTER")
      tick_precision = value_precision(price_filter&.fetch("tickSize").to_d)
      price_precision = [info.fetch("quotePrecision"), tick_precision].min

      {
        "id"               => info.fetch("symbol"),
        "base_unit"        => info.fetch("baseAsset"),
        "quote_unit"       => info.fetch("quoteAsset"),
        "min_price"        => price_filter&.fetch("minPrice").to_f,
        "max_price"        => price_filter&.fetch("maxPrice").to_f,
        "min_amount"       => get_min_quantity(market),
        "amount_precision" => get_amount_precision(market),
        "price_precision"  => price_precision
      }
    end


    def get_deposit_address(currency)
      rest_api(:get, "/sapi/v1/capital/deposit/address", coin: currency)
    end

    # Private methods

    private

    def headers
      {
        "Content-Type" => "application/json",
        "X-MBX-APIKEY" => @api_key
      }
    end

    def signature(query)
      OpenSSL::HMAC.hexdigest(
        OpenSSL::Digest.new("sha256"),
        @secret,
        query
      )
    end

    def timestamp
      DateTime.now.strftime("%Q")
    end

    def query(params=[])
      {timestamp: timestamp}.merge(params).map {|k, v| "#{k}=#{v}" }.join("&")
    end

    def rest_api(verb, endpoint_url, params={})
      # Is it ok to compact params here?
      q = query(params.compact)
      q = "#{q}&signature=#{signature(q)}"

      args = ["#{endpoint_url}?#{q}", nil, headers]

      response = @connection.send(verb, *args)
      response.assert_success!
      response.body
    rescue Faraday::Error => e
      case e
      when Faraday::ConnectionFailed, Faraday::TimeoutError
        raise ConnectionError, e
      else
        raise ConnectionError, e.response.body
      end
    end

  end
end
