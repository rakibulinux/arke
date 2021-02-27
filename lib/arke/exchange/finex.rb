# frozen_string_literal: true

require 'byebug'

module Arke::Exchange
  WEBSOCKET_CONNECTION_RETRY_DELAY = 0.75

  class Finex < Opendax
    def initialize(config)
      super
      @finex = true
      @bulk_order_support = config["bulk_order_support"] != false
      @bulk_limit = config["bulk_limit"] || 100
      @finex_ws_route = config["finex_ws_route"] || "open_finance"
      @reqid = 0
    end

    #
    # WebSocket
    #

    MSG_TYPE_REQUEST = 1
    MSG_TYPE_RESPONSE = 2
    MSG_TYPE_PUBLIC_EVENT = 3
    MSG_TYPE_PRIVATE_EVENT = 4

    EVENT_BALANCE_UPDATE      = "bu"
    EVENT_ORDER_CREATE        = "on"
    EVENT_ORDER_CANCEL        = "oc"
    EVENT_ORDER_UPDATE        = "ou"
    EVENT_ORDER_REJECT        = "or"
    EVENT_TRADE_              = "tr"
    EVENT_ORDERBOOK_INCREMENT = "obi"
    EVENT_ORDERBOOK_SNAPSHOT  = "obs"

    METHOD_SUBSCRIBE        = "subscribe"
    METHOD_LIST_ORDERS      = "list_orders"
    METHOD_GET_ORDERS       = "get_orders"
    METHOD_GET_ORDERTRADES  = "get_order_trades"
    METHOD_CREATE_ORDER     = "create_order"
    METHOD_CREATE_ORDERBULK = "create_bulk"
    METHOD_CANCEL_ORDER     = "cancel_order"
    METHOD_CANCEL_ORDERBULK = "cancel_bulk"

    ORDER_SIDE_SELL = "sell"
    ORDER_SIDE_BUY  = "buy"

    ORDER_STATE_PENDING = "p"
    ORDER_STATE_WAIT    = "w"
    ORDER_STATE_DONE    = "d"
    ORDER_STATE_REJECT  = "r"
    ORDER_STATE_CANCEL  = "c"

    ORDER_TYPE_LIMIT    = "l"
    ORDER_TYPE_MARKET   = "m"
    ORDER_TYPE_POSTONLY = "p"

    TOPIC_BALANCES = "balances"
    TOPIC_ORDER    = "order"
    TOPIC_TRADE    = "trade"

    def ws_connect(ws_id)
      raise "can't use finex ws without authentication" if ws_id == :public

      @markets_to_listen << "daiusdt" # FIXME
      @ws_url = "%s/api/v2/%s" % [@ws_base_url, @finex_ws_route]

      unless @ping_fiber
        @ping_fiber = Fiber.new do
          EM::Synchrony.add_periodic_timer(53) do
            ws_write_message(ws_id, "ping")
          end
        end
        @ping_fiber.resume
      end

      logger.info { "ACCOUNT:#{id} Websocket connecting to #{@ws_url}" }

      @ws = Faye::WebSocket::Client.new(@ws_url, [], headers: generate_headers())

      @ws.on(:open) do |_e|
        @ws_connected = true
        @ws_queues[ws_id].pop do |msg|
          ws_write_message(ws_id, msg)
        end
        logger.info { "ACCOUNT:#{id} Websocket #{ws_id} connected" }
      end

      @ws.on(:message) do |msg|
        ws_read_message(ws_id, msg)
      end

      @ws.on(:close) do |e|
        @ws = nil
        @ws_connected = false
        logger.error "ACCOUNT:#{id} Websocket disconnected: #{e.code} Reason: #{e.reason}"
        # byebug
        Fiber.new do
          EM::Synchrony.sleep(WEBSOCKET_CONNECTION_RETRY_DELAY)
          ws_connect(ws_id)
        end.resume
      end
    end

    def reqid
      @reqid += 1
    end

    def subscribe
      if flag?(LISTEN_PUBLIC_ORDERBOOK) && !@markets_to_listen.empty?
        streams = []
        @markets_to_listen.each do |id|
          streams << "#{id}.orderbook"
        end
        ws_write_message(:private, JSON.dump([MSG_TYPE_REQUEST, reqid, "subscribe", ["public", [streams]]]))
      end

      streams = [TOPIC_BALANCES, TOPIC_ORDER, TOPIC_TRADE]
      ws_write_message(:private, JSON.dump([MSG_TYPE_REQUEST, reqid, "subscribe", ["private", streams]]))
    end

    def ws_read_message(ws_id, msg)
      # logger.debug { "ACCOUNT:#{id} received #{ws_id} websocket message: #{msg.data}" } if @debug
      logger.info { "ACCOUNT:#{id} received #{ws_id} websocket message: #{msg.data}" }

      msg = JSON.parse(msg.data)

      case msg.first
      when MSG_TYPE_RESPONSE
        _, request_id, method, args = msg
        ws_handle_response(request_id, method, args)

      when MSG_TYPE_PUBLIC_EVENT
        _, method, args = msg
        ws_handle_public_event(method, args)

      when MSG_TYPE_PRIVATE_EVENT
        _, method, args = msg
        ws_handle_private_event(method, args)

      else
        raise "Unexpected event type in message: #{msg.data}"
      end
    end

    def ws_handle_response(request_id, method, args)
      # TODO
    end

    def ws_handle_public_event(method, _args)
      case method
      when "kline"
      when "tikers"
      when "trade"
      when "obSnap"
      when "obInc"
      else
        log.error "Unknown public event method #{method}"
      end

      # msg.each do |key, content|
      #   case key
      #   when /([^.]+)\.ob-snap/
      #     @books[Regexp.last_match(1)] = {
      #       book:     create_or_update_orderbook(Arke::Orderbook::Orderbook.new(Regexp.last_match(1)), content),
      #       sequence: content["sequence"],
      #     }
      #   when /([^.]+)\.ob-inc/
      #     if @books[Regexp.last_match(1)].nil?
      #       return logger.error { "Received a book increment before snapshot on market #{Regexp.last_match(1)}" }
      #     end

      #     if content["sequence"] != @books[Regexp.last_match(1)][:sequence] + 1
      #       logger.error { "Sequence out of order (previous: #{@books[Regexp.last_match(1)][:sequence]} current:#{content['sequence']}, reconnecting websocket..." }
      #       return @ws.close
      #     end
      #     bids = content["bids"]
      #     asks = content["asks"]
      #     create_or_update_orderbook(@books[Regexp.last_match(1)][:book], {"bids" => [bids]}) if bids && !bids.empty?
      #     create_or_update_orderbook(@books[Regexp.last_match(1)][:book], {"asks" => [asks]}) if asks && !asks.empty?
      #     @books[Regexp.last_match(1)][:sequence] = content["sequence"]
      #   end
      # end
    end

    def ws_handle_private_event(method, args)
      case method

      when EVENT_BALANCE_UPDATE
        # D, [2021-02-27T22:26:37.769692 #81277] DEBUG -- : ACCOUNT:backup received private websocket message: [4,"bu",[["omg","312088.042","197224.26"],["xrp","2402766.67","2645820.18"],["dai","17584.34","32415.66"],["eth","96825.84466","3340.96876"],["usdt","4.1729445","4388239.43915337"],["btc","33.272455","76.892979"],["uni","49850.22","3019.34"],["aave","49706.6239","206.7892"],["bnb","51576.294","0"],["link","45137.472","6414.952"],["rly","5000000","0"],["solve","5000000","0"],["eur","0.019458","99999.980542"]]]

      # when EVENT_ORDER_CREATE
        
      when EVENT_ORDER_CANCEL
        # E, [2021-02-27T22:26:37.768719 #81277] ERROR -- : Unkown private event method oc with args: ["btcusdt", 3293581, "2698b7b8-7931-11eb-b472-96ba6c261859", "sell", "c", "l", "47326.62", "0", "0.0174", "0.0174", "0", 0, 1614453757]

      when "trade"

      when "systemEvent"
        msg, uid = args
        if msg == "authenticated"
          @uid = uid
          subscribe
        else
          logger.error "Unexpected systemEvent args: #{args}"
        end
      else
        logger.error "Unkown private event method #{method} with args: #{args}"
      end
      # if msg["trade"]
      #   trd = msg["trade"]
      #   logger.debug { "ACCOUNT:#{id} trade received: #{trd}" }

      #   if trd["order_id"]
      #     amount = trd["amount"].to_f
      #     side = trd["side"].to_sym
      #     notify_private_trade(
      #       Arke::Trade.new(trd["id"], trd["market"].upcase, side, amount, trd["price"].to_f, trd["total"],
      #                       trd["order_id"]), true
      #     )
      #   else
      #     amount = trd["volume"].to_f
      #     notify_private_trade(
      #       Arke::Trade.new(trd["id"], trd["market"].upcase, :buy, amount, trd["price"].to_f, trd["total"],
      #                       trd["bid_id"]), false
      #     )
      #     notify_private_trade(
      #       Arke::Trade.new(trd["id"], trd["market"].upcase, :sell, amount, trd["price"].to_f, trd["total"],
      #                       trd["ask_id"]), false
      #     )
      #   end
      #   return
      # end

      # if msg["order"]
      #   ord = msg["order"]
      #   side = side_from_kind(ord["kind"])
      #   order = Arke::Order.new(ord["market"].upcase, ord["price"].to_f, ord["remaining_volume"].to_f, side)
      #   order.id = ord["id"]
      #   case ord["state"]
      #   when "wait"
      #     notify_created_order(order)
      #   when "cancel", "done"
      #     notify_deleted_order(order)
      #   end
      #   return
      # end

      # if msg["balances"]
      #   update_balances(msg["balances"].map {|currency, (free, locked)|
      #     free = free.to_d
      #     locked = locked.to_d
      #     {
      #       "currency" => currency,
      #       "free"     => free,
      #       "locked"   => locked,
      #       "total"    => free + locked,
      #     }
      #   })
      #   return
      # end

    end

    #
    # Orders
    #

    def stop_order_bulk(orders)
      orders.in_groups_of(@bulk_limit, false) do |orders_group|
        url = "#{@finex_route}/market/bulk/orders_by_id"
        response = delete(url, orders_group.map(&:id))
        raise response.body["errors"].to_s if response.body.is_a?(Hash) && response.body["errors"]

        # Hotfix to prevent arke to try to cancel in loop already canceled orders
        orders_group.each {|order| notify_deleted_order(order) }
      end
    end
  end
end
