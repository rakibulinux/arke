# frozen_string_literal: true

module Arke
  # Main event ractor loop
  class Reactor
    class StrategyNotFound < StandardError; end
    include Arke::Helpers::Flags
    attr_reader :logger

    FETCH_OPEN_ORDERS_PERIOD = 600

    def initialize(strategies_configs, accounts_configs, dry_run)
      @dry_run = dry_run
      @logger = Arke::Log
      init_accounts(accounts_configs)
      init_strategies(strategies_configs)
    end

    def report_fatal(e, id)
      logger.fatal "#{e}: #{e.backtrace.join("\n")}"
      logger.fatal "ID:#{id} Strategy stopped"
    end

    def init_accounts(accounts_configs)
      @accounts = {}
      @markets = []
      accounts_configs.each do |config|
        account = @accounts[config["id"]] = Arke::Exchange.create(config)
        executor = ActionExecutor.new(account, purge_on_push: true)
        account.executor = executor
      end
    end

    def build_market(config, mode)
      return nil unless config

      market_id = config["market_id"]
      if market_id.nil? && config["market"]&.key?("id")
        market_id = config["market"]["id"]
        logger.warn "market:id in configuration will be deprecated in favor of market_id"
      end
      @markets << Market.new(market_id, get_account(config["account_id"]), mode)
      @markets.last
    end

    def get_account(id)
      account = @accounts[id]
      raise "Account not found id: #{id}" unless @accounts[id]

      account
    end

    def init_strategies(strategies_configs)
      strategies = []
      strategies_configs.map do |config|
        sources = Array(config["sources"]).map {|config| build_market(config, DEFAULT_SOURCE_FLAGS) }
        target = build_market(config["target"], DEFAULT_TARGET_FLAGS)
        strategy = Arke::Strategy.create(sources, target, config, self)
        if config["fx"]
          type = config["fx"]["type"]
          raise "missing type in fx configuration for strategy id #{strategy['id']}" if type.to_s.empty?

          fx_klass = Arke::Fx.const_get(type.capitalize)
          strategy.fx = fx_klass.new(config["fx"])
        end
        strategies << strategy
      end
      @strategies = strategies
    end

    def find_strategy(id)
      return nil if id.nil?

      strategy = @strategies.find {|s| s.id == id }
      raise StrategyNotFound.new("Strategy not found with id: #{id}") unless strategy

      strategy
    end

    def run_metrics_server!
      registry = Prometheus::Client::Registry.new
      app = Rack::Builder.new do |builder|
        builder.use Rack::CommonLogger
        builder.use Rack::ShowExceptions
        builder.use Rack::Deflater
        builder.use Prometheus::Middleware::Exporter, registry: registry
        builder.run ->(_) { [404, {"Content-Type" => "text/html"}, ["Not found\n"]] }
      end
      thin = Rack::Handler.get("thin")
      thin.run(app, Port: 4242)
    end

    def run
      EM.synchrony do
        run_metrics_server!

        trap("INT") { stop }
        trap("TERM") { stop }

        # Fetch open orders if needed
        @markets.each(&:start)

        # Connect Private Web Sockets
        @accounts.each do |_id, account|
          account.ws_connect_private if account.flag?(WS_PRIVATE)
        end

        # Setup balance fetcher
        update_balances
        Fiber.new do
          EM::Synchrony.add_periodic_timer(23) { update_balances }
        end.resume

        # Initialize executors & fx classes
        @strategies.each do |strategy|
          strategy.target.account.executor.create_queue(strategy.id, strategy.delay)
          strategy.sources.each do |source|
            source.account.executor.create_queue(strategy.id)
          end
          strategy.fx&.start
        end
        @accounts.each_value {|account| account.executor.start } unless @dry_run

        # Connect Public Web Sockets
        @accounts.each do |_id, account|
          next if !account.flag?(WS_PUBLIC) || account.flag?(WS_PRIVATE)

          account.ws_connect_public
        end

        # Start strategies
        @strategies.each do |strategy|
          Fiber.new do
            EM::Synchrony.add_periodic_timer(FETCH_OPEN_ORDERS_PERIOD) { fetch_openorders(strategy) }

            if strategy.delay_the_first_execute
              logger.warn { "ID:#{strategy.id} Delaying the first execution" }
            else
              tick(strategy)
            end

            if strategy.period_random_delay.to_f.positive?
              add_periodic_random_timer(strategy)
            else
              strategy.timer = EM::Synchrony.add_periodic_timer(strategy.period) { tick(strategy) }
            end
          rescue StandardError => e
            report_fatal(e, strategy.id)
          end.resume
        end
      end
    end

    def add_periodic_random_timer(strategy)
      delay = strategy.period + rand(strategy.period_random_delay)
      strategy.timer = EM::Synchrony.add_timer(delay) do
        tick(strategy)
        add_periodic_random_timer(strategy)
      end
      logger.info { "ID:#{strategy.id} Scheduled next run in #{delay}s" }
    end

    def tick(strategy)
      unless strategy.target.account.ws
        logger.warn { "ID:#{strategy.id} Skipping strategy execution since the websocket is not connected" }
        return
      end

      linked_strategy = find_strategy(strategy.linked_strategy_id)
      if linked_strategy && linked_strategy.target.account.ws.nil?
        logger.warn { "ID:#{strategy.id} Skipping strategy execution since linked strategy websocket is not connected" }
        return
      end

      update_orderbooks(strategy)
      execute_strategy(strategy)
    rescue StandardError => e
      logger.error { "ID:#{strategy.id} #{e}" }
      logger.error { "#{e}: #{e.backtrace.join("\n")}" }
    end

    def update_balances
      @accounts.values.each do |ex|
        next unless ex.flag?(FETCH_PRIVATE_BALANCE)
        unless ex.respond_to?(:get_balances)
          raise "ACCOUNT:#{ex.id} Exchange #{ex.driver} doesn't support get_balances".red
        end

        begin
          ex.fetch_balances
        rescue StandardError => e
          logger.error { "ACCOUNT:#{ex.id} Fetching balances on #{ex.driver} failed: #{e}\n#{e.backtrace.join("\n")}" }
        end
      end
    end

    def update_orderbooks(strategy)
      strategy.sources.each do |market|
        if market.flag?(FETCH_PUBLIC_ORDERBOOK)
          logger.debug { "ID:#{strategy.id} Update #{market.account.driver} #{market.id} orderbook" }
          market.update_orderbook
        else
          logger.debug { "ID:#{strategy.id} DO NOT UPDATE #{market.account.driver} #{market.id} orderbook" }
        end
      end
    end

    def execute_strategy(strategy)
      desired_orderbook, price_levels = strategy.call()

      if strategy.debug
        strategy.debug_infos.each do |label, data|
          logger.debug { "#{label}: #{data}".yellow }
        end
      end
      return unless desired_orderbook

      if strategy.fx
        desired_orderbook, price_levels = strategy.fx.apply(desired_orderbook, price_levels)
      end

      logger.debug { "ID:#{strategy.id} Current Orderbook\n#{strategy.target.open_orders}" }
      logger.debug { "ID:#{strategy.id} Desired Orderbook\n#{desired_orderbook}" }
      return if @dry_run

      scheduler_opts = {
        price_levels:         price_levels,
        strategy_id:          strategy.id,
        max_amount_per_order: strategy.max_amount_per_order,
      }
      scheduler_opts[:limit_asks_base] = strategy.limit_asks_base if strategy.respond_to?(:limit_asks_base)
      scheduler_opts[:limit_bids_base] = strategy.limit_bids_base if strategy.respond_to?(:limit_bids_base)
      scheduler_opts[:limit_bids_quote] = strategy.limit_bids_quote if strategy.respond_to?(:limit_bids_quote)

      scheduler = ::Arke::Scheduler::Smart.new(
        strategy.target.open_orders,
        desired_orderbook,
        strategy.target,
        scheduler_opts
      )
      strategy.target.account.executor.push(strategy.id, scheduler.schedule)
    end

    def fetch_openorders(strategy)
      strategy.target.account.executor.fetch_openorders(strategy.target)
    end

    # Stops workers and strategy execution
    def stop
      puts "Shutting down arke"
      EM.stop
    end
  end
end
