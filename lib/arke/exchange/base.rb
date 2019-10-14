# frozen_string_literal: true

module Arke::Exchange
  # Base class for all exchanges
  class Base
    include ::Arke::Helpers::Precision

    attr_reader :delay, :driver, :opts, :id, :ws, :host, :key, :secret
    attr_accessor :timer, :executor

    DEFAULT_DELAY = 1

    def initialize(opts)
      @driver = opts["driver"]
      @host = opts["host"]
      @api_key = opts["key"]
      @secret = opts["secret"]
      @id = opts["id"]
      @delay = (opts["delay"] || DEFAULT_DELAY).to_f
      @adapter = opts[:faraday_adapter] || :em_synchrony
      @opts = opts
      @balances = nil
      @timer = nil
      @trades_cb = []
      @created_order_cb = []
      @deleted_order_cb = []
      load_platform_markets(opts["driver"]) if opts[:load_platform_markets]
    end

    def info(msg)
      Arke::Log.info "#{@driver}: #{msg}"
    end

    def to_s
      "Exchange::#{self.class} config: #{@opts}"
    end

    # Registers callbacks on trade event in strategy
    def register_on_trade_cb(&cb)
      @trades_cb << cb
    end

    def register_on_created_order(&cb)
      @created_order_cb << cb
    end

    def register_on_deleted_order(&cb)
      @deleted_order_cb << cb
    end

    # Is executed in exchange when trade event is pushed to the websocket
    def notify_trade(trade)
      @trades_cb.each {|cb| cb&.call(trade) }
    end

    def notify_created_order(order)
      @created_order_cb.each {|cb| cb&.call(order) }
    end

    def notify_deleted_order(order)
      @deleted_order_cb.each {|cb| cb&.call(order) }
    end

    def start
      raise "start not implemented"
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

    def fetch_balances
      balances = get_balances()
      @balances = balances
    end

    def balance(currency)
      return nil unless @balances
      @balances.find {|b| b["currency"].casecmp?(currency) }
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
