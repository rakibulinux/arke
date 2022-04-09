# frozen_string_literal: true

module Arke::Exchange
  class Tradepoint < Base
    def initialize(opts)
      super
      @markets = opts["markets"]

      dapr_port = ENV["DAPR_HTTP_PORT"]
      raise "DAPR_HTTP_PORT is not set" if dapr_port.to_s.empty?

      @dapr = Faraday.new(url: "http://localhost:#{dapr_port}") do |builder|
        builder.adapter(:em_synchrony)
        builder.response :json
      end
    end

    def ws_connect(ws_id)
      raise "Unsupported websocket type #{ws_id}" unless ws_id == :public

      return unless flag?(LISTEN_PUBLIC_ORDERBOOK)
      @markets_to_listen.each do |market_id|
        stream, market = market_id.split(":")
        raise "Source market_id should be formated like \"binance:BTCUSDT\"" if stream.nil? or market.nil?
        logger.info { "ACCOUNT:#{id} stream #{stream} orderbook #{market} initializing" }
        Fiber.new { initialize_orderbook(stream, market) }.resume
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

    def initialize_orderbook(stream, market)
      market_id = [stream, market].join(":")
      @books[market_id] = {
        init: true,
        inc:  []
      }
      sequence, ob = fetch_orderbook(stream, market)
      @books[market_id][:book] = ob
      @books[market_id][:init] = false
      @books[market_id][:inc].each do |data|
        next if data["u"] <= sequence

        handle_orderbook_update(data)
      end
      logger.info { "ACCOUNT:#{id} stream #{stream} orderbook #{market} initialized" }
    end

    def fetch_orderbook(stream, market)
      body = {
        "market" => market,
        "id" => stream,
      }
      headers = {
        "Content-Type" => "application/json",
      }
      sequence, asks, bids = @dapr.post do |req|
        req.url URI.join(@dapr.url_prefix, "/v1.0/invoke/exchange-arke/method/orderbook")
        req.body = body
        req.headers = headers
      end
      orderbook = Arke::Orderbook::Orderbook.new(market)
      Array(bids).each do |order|
        orderbook.update(
          build_order(order, :buy)
        )
      end
      Array(asks).each do |order|
        orderbook.update(
          build_order(order, :sell)
        )
      end
      [sequence, orderbook]
    end

    def update_orderbook(market_id)
      return @books[market_id][:book] if @books[market_id]
    end

    def market_config(market_id)
      stream, market = market_id.split(":")
      body = {
        "market" => market,
        "id" => stream,
      }
      headers = {
        "Content-Type" => "application/json",
      }
      @dapr.post do |req|
        req.url URI.join(@dapr.url_prefix, "/v1.0/invoke/exchange-arke/method/market-config")
        req.body = body
        req.headers = headers
      end
    end

    def create_or_update_orderbook(orderbook, bids, asks)
      (bids || []).each do |price, amount|
        amount = amount.to_d
        if amount == 0
          orderbook[:buy].delete(price.to_d)
        else
          orderbook.update_amount(:buy, price.to_d, amount)
        end
      end
      (asks || []).each do |price, amount|
        amount = amount.to_d
        if amount == 0
          orderbook[:sell].delete(price.to_d)
        else
          orderbook.update_amount(:sell, price.to_d, amount)
        end
      end
    end

    def handle_ob_inc(stream, market, sequence, asks, bids)
      market_id = [stream, market].join(":")

      if sequence != @books[market_id][:sequence] + 1
        logger.error { "Sequence out of order (previous: #{@books[market_id][:sequence]} current:#{sequence}, reconnecting websocket..." }
        return
      end
      create_or_update_orderbook(@books[market_id][:book], bids, asks)
      @books[market_id][:sequence] = args[1]
    end
  end
end
