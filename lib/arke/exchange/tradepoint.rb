# frozen_string_literal: true

module Arke::Exchange
  class Tradepoint < Base
    class OrderbookSequenceError < StandardError; end

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
    # Intialization phase for orderbook:
    # 1. bufferize orderbook increments until we receive the snapshot
    # 2. ignore increments with lower sequence than orderbook snapshot
    # 3. apply others increments on the snapshot
    # 4. very that every new increment has the next sequence number
    # 5. restart orderbook init phase if a increment sequence doesn't match
    #
    def initialize_orderbook(stream, market)
      market_id = [stream, market].join(":")
      @books[market_id] = {
        init: true,
        inc:  []
      }
      snap_sequence, ob = fetch_orderbook(stream, market)
      @books[market_id][:book] = ob
      @books[market_id][:init] = false
      @books[market_id][:sequence] = snap_sequence
      @books[market_id][:inc].each do |inc_sequence, bids, asks|
        next if inc_sequence <= snap_sequence
        handle_ob_inc(stream, market, inc_sequence, bids, asks)
      end
      logger.info { "ACCOUNT:#{id} stream #{stream} orderbook #{market} initialized" }
    rescue OrderbookSequenceError
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
      end.body
      orderbook = Arke::Orderbook::Orderbook.new(market)
      create_or_update_orderbook(orderbook, asks, bids)
      [sequence, orderbook]
    end

    def update_orderbook(market_id)
      return @books[market_id][:book] if @books[market_id]
    end

    def create_or_update_orderbook(orderbook, asks, bids)
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

      if @books[market_id][:init]
        @books[market_id][:inc] << [sequence, asks, bids]
        return
      end

      prev_sequence = @books[market_id][:sequence]

      if sequence != prev_sequence + 1
        @books[market_id] = {
          init: true,
          inc:  []
        }
        EM.add_timer(0.1) { initialize_orderbook(stream, market) }
        error_msg = "Sequence out of order (previous: #{prev_sequence} current:#{sequence}, re-initializing the orderbook..."
        logger.error(error_msg)
        raise OrderbookSequenceError.new(error_msg)
      end
      create_or_update_orderbook(@books[market_id][:book], asks, bids)
      @books[market_id][:sequence] = sequence
    end

    #
    # REST APIs
    #

    def invoke(method, body)
      @dapr.post do |req|
        req.url URI.join(@dapr.url_prefix, "/v1.0/invoke/exchange-arke/method/#{method}")
        req.body = body
        req.headers = {
          "Content-Type" => "application/json",
        }
      end
    end

    def market_config(market_id)
      stream, market = market_id.split(":")
      dapr_post("market-config", {
        "market" => market,
        "id" => stream,
      })
    end

    def get_balances
      raise "FIXME: we don't have the account id?"
      stream, market = market_id.split(":")
      dapr_post("balances", {
        "id" => stream,
      })
    end

    def create_order(order)
      stream, market = order.market.split(":")
      dapr_post("create-order", {
        "account_id" => stream,
        "market" => market,
        "price" => order.price.to_s,
        "amount" => order.amount.to_s,
        "side" => order.side,
        "type" => order.type,
      })
      order
    end

    def stop_order(order)
      dapr_post("stop-order", {
        "account_id" => stream,
        "market" => order.market,
        "order_id" => order.id,
      })
      order
    end

    def cancel_all_orders(market_id)
      stream, market = market_id.split(":")
      dapr_post("stop-order", {
        "account_id" => stream,
        "market" => market,
      })
    end

    def fetch_openorders(market_id)
      stream, market = market_id.split(":")
      dapr_post("stop-order", {
        "account_id" => stream,
        "market" => market,
      })
    end
  end
end
