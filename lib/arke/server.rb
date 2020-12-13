module Arke
  class Server
    attr_reader :logger

    def initialize
      require "em-websocket"
      require "concurrent-ruby"

      @ws_host = ENV.fetch("ARKE_WS_HOST", "0.0.0.0")
      @ws_port = ENV.fetch("ARKE_WS_PORT", "8081")
      Arke::Log.level = "INFO"
      @logger = Arke::Log
      @bots = Concurrent::Hash.new
    end

    def run
      EM.run do
        EM::WebSocket.run(host: @ws_host, port: @ws_port) do |ws|
          ws.onopen do |handshake|
            @logger.info "New websocket connection #{handshake.path}"
            ws.send "Hello Client, you connected to #{handshake.path}"
          end

          ws.onmessage {|msg| on_message(ws, msg) }

          ws.onclose do
            @logger.info "Websocket connection closed #{ws}"
          end
        end
        @logger.info "Webosocket server listenning on #{@ws_host}:#{@ws_port}"
      end
    end

    def respond(ws, req_id, method, params=nil)
      ws.send [2, req_id, method, params].compact.to_json
    end

    def on_message(ws, msg)
      puts "Recieved message: #{msg}"
      type, req_id, method, params = JSON.parse(msg)

      raise "Unexpected method type" if type != 1

      case method
      when "ping"
        respond(ws, req_id, "pong")
      when "start_bot"
        start_bot(req_id, ws, params)
      when "stop_bot"
        stop_bot(req_id, ws, params)
      when "subscribe_logs"
      end

    rescue StandardError => e
      logger.error "#{e}"
    end

    def start_bot(req_id, ws, params)
      bot_id = params["bot_id"]
      raise "bot_id missing" if bot_id.nil?

      device = ::Arke::DispatchDevice.new
      logger = Logger.new(device)

      th = Thread.new do
        Arke::Reactor.new(params["strategies"], params["accounts"], false).run
      rescue StandardError => e
        logger.fatal("Thread received a fatal error: #{e}")
      ensure
        device.close
        @bots.delete(bot_id)
      end

      @bots[bot_id] = OpenStruct.new(th: th, logger: logger, device: device)
    end

    def stop_bot(req_id, ws, _params)
      bot_id = params["bot_id"]
      raise "bot_id missing" if bot_id.nil?

      bot = @bots[bot_id]
      if bot.nil?
        respond(ws, req_id, "stop_bot", error: "bot is not running")
      else
        Thread.kill(bot.th)
        bot.device.close
        @bots.delete(bot_id)
        respond(ws, req_id, "stop_bot", success: "bot stopped")
      end
    end

    def subscribe_logs(bot_id); end
  end
end
