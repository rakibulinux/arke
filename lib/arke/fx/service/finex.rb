# frozen_string_literal: true

module Arke::Fx::Service
  class Finex
    include Singleton
    attr_reader :logger
    attr_writer :host

    TYPE_REQUEST = 1
    TYPE_PUBLIC_EVENT = 3
    WEBSOCKET_CONNECTION_RETRY_DELAY = 2

    def initialize
      @logger = Arke::Log
      @host = "localhost:8080"
      @pairs = []
      @books = {}
    end

    def register(pair)
      @pairs << pair unless @pairs.include?(pair)
    end

    def start
      return unless @ws.nil?

      ws_connect
    end

    def ws_url
      streams = @pairs.map {|pair| pair.downcase.to_s }
      "ws://#{@host}?stream=#{streams.join(',')}"
    end

    def ws_connect
      @ws = Faye::WebSocket::Client.new(ws_url)
      @ws.on(:open) do |_e|
        @ws_connected = true
        logger.info { "FINEX-FX: Websocket connected" }
      end

      @ws.on(:message) do |msg|
        ws_read_message(JSON.parse(msg.data))
      end

      @ws.on(:close) do |e|
        @ws = nil
        @ws_connected = false
        logger.error "FINEX-FX: Websocket disconnected: #{e.code} Reason: #{e.reason}"
        Fiber.new do
          EM::Synchrony.sleep(WEBSOCKET_CONNECTION_RETRY_DELAY)
          ws_connect()
        end.resume
      end
    end

    def ws_read_message(msg)
      type, request_id, data = msg
      case type
      when TYPE_PUBLIC_EVENT
        case request_id
        when "forex"
          pair, price, _, updated_at = data
          @books[pair] = {
            price:      price.to_d,
            updated_at: updated_at
          }
          logger.info { "FINEX-FX: #{pair}: #{price}" }
        end
      end
    end

    def rate(pair)
      raise "Finex fx not ready" unless @books[pair]

      @books[pair][:price]
    end
  end
end
