# frozen_string_literal: true

module Arke::Recorder
  class Reactor
    class StrategyNotFound < StandardError; end

    # * @shutdown is a flag which controls strategy execution
    def initialize(config, dry_run)
      @shutdown = false
      @dry_run = dry_run
      @period = config["period"]
      init_storage(config)
      init_exchanges(config)
    end

    def init_storage(config)
      @storage = ::Arke::Recorder::Storage.const_get(config["storage"]["driver"].capitalize).new(config)
    end

    def init_exchanges(config)
      @exchanges = \
        config["exchanges"].map do |ex_config|
          build_exchange(ex_config)
        end
    end

    def build_exchange(config)
      exchange = Arke::Exchange.create(config)
      exchange.executor = Arke::ActionExecutor.new(exchange)
      exchange.register_on_public_trade_cb(&@storage.method(:on_trade))
      exchange
    end

    def report_fatal(e, market)
      Arke::Log.fatal "#{e}: #{e.backtrace.join("\n")}"
      Arke::Log.fatal "#{market.account.host}:#{market.id} Market recording stopped"
    end

    def log(market, message)
      Arke::Log.info("#{market.account.host}:#{market.id} #{message}")
    end

    # def tick(market)
    #   log(market, "updating orderbook")
    #   ob = market.update_orderbook
    #   pp(
    #     asks: ob.stats(:sell),
    #     bids: ob.stats(:buy)
    #   )
    # end

    def run
      EM.synchrony do
        trap("INT") { stop }

        @exchanges.each do |exchange|
          Fiber.new do
            exchange.ws_connect_public
            exchange.executor.start
            # EM::Synchrony.add_periodic_timer(@period) { tick(market) }
            # tick(market)
            stop if @dry_run
          rescue StandardError => e
            report_fatal(e, market)
          end.resume
        end
      end
    end

    def stop
      puts "Shutting down"
      @shutdown = true
      exit(42)
    end
  end
end
