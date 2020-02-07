# frozen_string_literal: true

module Arke::Exchange
  # Base class for all exchanges
  class Base
    include ::Arke::Helpers::Precision
    include ::Arke::Helpers::Flags

    attr_reader :delay, :driver, :opts, :id, :ws, :host, :key, :secret, :logger
    attr_accessor :timer, :executor

    DEFAULT_DELAY = 1
    WEBSOCKET_CONNECTION_RETRY_DELAY = 2

    def initialize(opts)
      @logger = Arke::Log
      @driver = opts["driver"]
      @debug = opts["debug"] == true
      @host = opts["host"]
      @api_key = opts["key"]
      @secret = opts["secret"]
      @id = opts["id"]
      @delay = (opts["delay"] || DEFAULT_DELAY).to_f
      @adapter = opts[:faraday_adapter] || :em_synchrony
      @opts = opts
      @balances = nil
      @forced_balances = []
      @timer = nil
      @private_trades_cb = []
      @public_trades_cb = []
      @created_order_cb = []
      @deleted_order_cb = []
      @ws_queues = {
        public:  EM::Queue.new,
        private: EM::Queue.new,
      }
      @ws_status = {
        public:  false,
        private: false,
      }
      load_platform_markets(opts["driver"]) if opts[:load_platform_markets]
      update_forced_balance(opts["balances"]) if opts["balances"]
    end

    def ws_connect(ws_id)
      logger.info { "ACCOUNT:#{id} Websocket connecting to #{@ws_url}" }
      raise "websocket url missing for account #{id}" unless @ws_url

      headers = if ws_id == :private && respond_to?(:generate_headers)
                  generate_headers()
                else
                  {}
                end

      @ws = Faye::WebSocket::Client.new(@ws_url, [], headers: headers)

      @ws.on(:open) do |_e|
        @ws_status[ws_id] = true
        @ws_queues[ws_id].pop do |msg|
          ws_write_message(ws_id, msg)
        end
        logger.info { "ACCOUNT:#{id} Websocket connected" }
      end

      @ws.on(:message) do |msg|
        ws_read_message(ws_id, msg)
      end

      @ws.on(:close) do |e|
        @ws = nil
        @ws_status[ws_id] = false
        logger.error "ACCOUNT:#{id} Websocket disconnected: #{e.code} Reason: #{e.reason}"
        Fiber.new do
          EM::Synchrony.sleep(WEBSOCKET_CONNECTION_RETRY_DELAY)
          ws_connect(ws_id)
        end.resume
      end
    end

    def ws_connect_public
      ws_connect(:public)
    end

    def ws_connect_private
      ws_connect(:private)
    end

    def ws_write_message(ws_id, msg)
      unless @ws_status[ws_id]
        @ws_public_messages_out.push(msg)
        return
      end
      logger.debug { "ACCOUNT:#{id} pushing websocket message: #{msg}" }
      @ws.send(msg)
    end

    def ws_read_public_message(msg)
      logger.info { "ACCOUNT:#{id} received public message: #{msg}" }
    end

    def ws_read_private_message(msg)
      logger.info { "ACCOUNT:#{id} received private message: #{msg}" }
    end

    def ws_read_message(ws_id, msg)
      logger.debug { "ACCOUNT:#{id} received websocket message: #{msg.data}" }

      object = JSON.parse(msg.data)
      case ws_id
      when :public
        ws_read_public_message(object)
      when :private
        ws_read_private_message(object)
      end
    end

    def info(msg)
      logger.info "#{@driver}: #{msg}"
    end

    def to_s
      "Exchange::#{self.class} config: #{@opts}"
    end

    def register_on_private_trade_cb(&cb)
      @private_trades_cb << cb
    end

    def register_on_public_trade_cb(&cb)
      @public_trades_cb << cb
    end

    def register_on_created_order(&cb)
      @created_order_cb << cb
    end

    def register_on_deleted_order(&cb)
      @deleted_order_cb << cb
    end

    def notify_public_trade(trade)
      @public_trades_cb.each {|cb| cb&.call(trade) }
    end

    def notify_private_trade(trade, trust_trade_info=false)
      @private_trades_cb.each {|cb| cb&.call(trade, trust_trade_info) }
    end

    def notify_created_order(order)
      @created_order_cb.each {|cb| cb&.call(order) }
    end

    def notify_deleted_order(order)
      @deleted_order_cb.each {|cb| cb&.call(order) }
    end

    def stop
      raise "stop not implemented"
    end

    def create_order(_order)
      raise "create_order not implemented"
    end

    def stop_order(_order)
      raise "stop_order not implemented"
    end

    def fetch_openorders(_market)
      raise "fetch_openorders not implemented"
    end

    def update_forced_balance(balances)
      @forced_balances = balances.map do |key, value|
        {
          "currency" => key,
          "free"     => value,
          "locked"   => 0,
          "total"    => value,
        }
      end
    end

    def fetch_balances
      if @forced_balances.empty?
        balances = get_balances()
        @balances = balances
      else
        @balances = @forced_balances
      end
    end

    def balance(currency)
      return nil unless @balances

      @balances.find {|b| b["currency"].casecmp?(currency) }
    end

    def market_config(_market)
      raise "#{self.class} doesn't support market_config"
    end

    def build_query(params)
      params.keys.sort.map {|k| "#{Faraday::Utils.escape(k)}=#{Faraday::Utils.escape(params[k])}" }.join("&")
    end

    def print
      return unless @orderbook

      puts "Exchange #{@driver} market: #{@market}"
      puts @orderbook.print(:buy)
      puts @orderbook.print(:sell)
    end

    def build_error(response)
      JSON.parse(response.body)
    rescue StandardError => e
      "Code: #{response.env.status} Message: #{response.env.reason_phrase}"
    end

    def load_platform_markets(platform)
      @platform_markets = PlatformMarket.where(platform: platform).each_with_object({}) {|p, h| h[p.market] = p.id }
    end
  end
end
