# frozen_string_literal: true
module Arke
  class Server < Sinatra::Base
    settings.logging = true

    configure do
      raise "APP_PORT undefined" if ENV['APP_PORT'].to_s.empty?
      set :port, ENV['APP_PORT'].to_i
      set :bind, '127.0.0.1'
      set :server, :thin
      set :threaded, false
      set :server_settings, signals: false
      set :logger, Logger.new(STDERR)
    end

    # Example of endpoint to receive cloud-events
    post "/ob-inc" do
      event = JSON.parse(request.body.read)
      logger.info "Received Event: #{event}"
    end

    # Endpoint used by dapr to fetch service configuration on start
    get "/dapr/config" do
      JSON.dump({
        entities: nil,
        actorIdleTimeout: "",
        actorScanInterval: "",
        drainOngoingCallTimeout: "",
        drainRebalancedActors: false
      })
    end

    # Endpoint used by dapr to fetch service subscription configuration on start
    get "/dapr/subscribe" do
      topics = []
      ::Arke::Server.markets.each do |market|
        if market.account.class == Arke::Exchange::Tradepoint
          stream, market = market.id.split(":")
          raise "wrong market id format for tradepoint, must be like: `binance.com:btcusdt`" if market.nil?
          topics << {pubsubname: "pubsub", topic: "ob-inc/#{stream}/#{market}", route: "/ob-inc"}
        end
      end
      JSON.dump(topics)
    end
  end
end
