# frozen_string_literal: true

module Arke
  # Main event ractor loop
  class Reactor
    class StrategyNotFound < StandardError; end

    # * @shutdown is a flag which controls strategy execution
    def initialize(strategies_configs, accounts_configs)
      @shutdown = false
      init_accounts(accounts_configs)
      update_balances
      init_strategies(strategies_configs)
    end

    def report_fatal(e, id)
      Arke::Log.fatal "#{e}: #{e.backtrace.join("\n")}"
      Arke::Log.fatal "ID:#{id} Strategy stopped"
    end

    def init_accounts(accounts_configs)
      @accounts = {}
      accounts_configs.each do |config|
        account = @accounts[config["id"]] = Arke::Exchange.create(config)
        executor = ActionExecutor.new(config["id"], account)
        account.executor = executor
      end
    end

    def build_market(config)
      Market.new(config["market"], get_account(config["account_id"]))
    end

    def get_account(id)
      account = @accounts[id]
      raise "Account not found id: #{id}" unless @accounts[id]

      account
    end

    def init_strategies(strategies_configs)
      strategies = []
      strategies_configs.map do |config|
        sources = Array(config["sources"]).map {|config| build_market(config) }
        target = config["target"] ? build_market(config["target"]) : nil
        strategies << Arke::Strategy.create(sources, target, config, self)
      rescue StandardError => e
        report_fatal(e, config["id"])
      end
      @strategies = strategies
    end

    def find_strategy(id)
      return nil if id.nil?

      strategy = @strategies.find {|s| s.id == id }
      raise StrategyNotFound.new("with id: #{id}") unless strategy

      strategy
    end

    def run
      EM.synchrony do
        trap("INT") { stop }
        @accounts.each do |id, account|
          account.start
        end

        Fiber.new do
          EM::Synchrony.add_periodic_timer(23) { update_balances }
        end.resume

        @strategies.each do |strategy|
          Fiber.new do
            Arke::Log.info("ID:#{strategy.id} Purging open orders on #{strategy.target.account.driver}")
            strategy.target.account.cancel_all_orders(strategy.target.id)
            strategy.target.account.executor.start

            if strategy.delay_the_first_execute
              Arke::Log.warn("ID:#{strategy.id} Delaying the first execution")
            else
              tick(strategy)
            end

            if strategy.period_random_delay
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
      Log.info "ID:#{strategy.id} Scheduled next run in #{delay}s"
    end

    def tick(strategy)
      unless strategy.target.account.ws
        Log.warn "ID:#{strategy.id} Skipping strategy execution since the websocket is not connected"
        return
      end

      linked_strategy = find_strategy(strategy.linked_strategy_id)
      if linked_strategy && linked_strategy.target.account.ws
        Log.warn "ID:#{strategy.id} Skipping strategy execution since linked strategy websocket is not connected"
        return
      end

      update_orderbooks(strategy)
      execute_strategy(strategy)
    rescue StandardError => e
      Log.error "ID:#{strategy.id} #{e}"
      Log.error "#{e}: #{e.backtrace.join("\n")}"
    end

    def update_balances
      @accounts.values.each do |ex|
        unless ex.respond_to?(:get_balances)
          raise "ACCOUNT:#{ex.id} Exchange #{ex.driver} doesn't support get_balances".red
        end

        begin
          Log.info "ACCOUNT:#{ex.id} Fetching balances on #{ex.driver}"
          ex.fetch_balances
        rescue StandardError => e
          Log.error("ACCOUNT:#{ex.id} Fetching balances on #{ex.driver} failed")
        end
      end
    end

    def update_orderbooks(strategy)
      strategy.sources.each do |market|
        Arke::Log.debug "ID:#{strategy.id} Update #{market.account.driver} #{market.id} orderbook"
        market.update_orderbook
      end
    end

    def execute_strategy(strategy)
      desired_orderbook = strategy.call

      if strategy.debug
        strategy.debug_infos.each do |label, data|
          ::Arke::Log.debug "#{label}: #{data}".yellow
        end
      end
      return unless desired_orderbook

      Log.debug "ID:#{strategy.id} Current Orderbook\n#{strategy.target.open_orders}"
      Log.debug "ID:#{strategy.id} Desired Orderbook\n#{desired_orderbook}"
      actions = ActionScheduler.new(strategy.target.open_orders, desired_orderbook, strategy.target).schedule
      strategy.target.account.executor.push(actions)
    end

    # Stops workers and strategy execution
    # * sets @shutdown flag to +true+
    # * broadcasts +:shutdown+ action to workers
    def stop
      puts "Shutdown trading"
      if @strategies.empty?
        EM.stop
      else
        Fiber.new do
          @strategies.each do |strategy|
            strategy.target.account.cancel_all_orders(strategy.target.id)
            EM.stop
          end
        end.resume
      end
      @shutdown = true
    end
  end
end
