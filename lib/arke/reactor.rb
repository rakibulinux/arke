require "ostruct"
require "faraday"
require "faraday_middleware"
require "em-synchrony"
require "em-synchrony/em-http"

require "arke/exchange"
require "arke/strategy"

module Arke
  # Main event ractor loop
  class Reactor
    class StrategyNotFound < StandardError; end

    # * @shutdown is a flag which controls strategy execution
    def initialize(strategies_configs, accounts_configs)
      @shutdown = false
      init_accounts(accounts_configs)
      init_strategies(strategies_configs)
    end

    def report_fatal(e, id)
      Arke::Log.fatal "#{e}: #{e.backtrace.join("\n")}"
      Arke::Log.fatal "ID:#{id} Strategy stopped"
    end

    def init_accounts(accounts_configs)
      @accounts = {}
      accounts_configs.each do |config|
        @accounts[config["id"]] = Arke::Exchange.create(config)
      end
    end

    def build_exchange_with_market(config)
      ex = @accounts[config["account_id"]]
      raise "Account not found id: #{config["account_id"]}" unless ex

      new_ex = ex.clone
      new_ex.configure_market(config["market"])
      new_ex
    end

    def register_strategy(strategy, id, sources, target, executor, debug = false)
      strategy_struct = OpenStruct.new({
        id: id,
        target: target,
        sources: sources,
        executor: executor,
        strategy: strategy,
        debug: debug,
      })
      @strategies << strategy_struct
    end

    def init_strategies(strategies_configs)
      update_balances
      @strategies = []

      strategies_configs.each do |config|
        begin
          sources = Array(config["sources"]).map { |config| build_exchange_with_market(config) }
          target = config["target"] ? build_exchange_with_market(config["target"]) : nil
          executor = ActionExecutor.new(config["id"], target, sources)
          strategy = Arke::Strategy.create(sources, target, config, executor, self)
          register_strategy(strategy, config["id"], sources, target, executor, config["debug"] ? true : false)
        rescue StandardError => e
          report_fatal(e, config["id"])
          nil
        end
      end
    end

    def find_strategy(id)
      strategy = @strategies.find{|s| s.id == id}
      raise StrategyNotFound.new("with id: #{id}") unless strategy
      strategy
    end

    def run
      EM.synchrony do
        trap("INT") { stop }

        Fiber.new do
          EM::Synchrony::add_periodic_timer(23) { update_balances }
        end.resume

        @strategies.each do |strategy|
          Fiber.new do
            begin
              Arke::Log.info("ID:#{strategy.id} Purging open orders on #{strategy.target.driver}")
              strategy.target.cancel_all_orders
              strategy.target.start
              strategy.executor.start

              if strategy.strategy.delay_the_first_execute
                Arke::Log.warn("ID:#{strategy.id} Delaying the first execution")
              else
                tick(strategy)
              end

              if strategy.strategy.period_random_delay
                add_periodic_random_timer(strategy)
              else
                strategy.timer = EM::Synchrony::add_periodic_timer(strategy.strategy.period) { tick(strategy) }
              end
            rescue StandardError => e
              report_fatal(e, strategy.id)
            end
          end.resume
        end
      end
    end

    def add_periodic_random_timer(strategy)
      delay = strategy.strategy.period + rand(strategy.strategy.period_random_delay)
      strategy.timer = EM::Synchrony::add_timer(delay) do
        tick(strategy)
        add_periodic_random_timer(strategy)
      end
      Log.info "ID:#{strategy.id} Scheduled next run in #{delay}s"
    end

    def tick(strategy)
      begin
        update_orderbooks(strategy)
        execute_strategy(strategy)
      rescue StandardError => e
        Log.error "ID:#{strategy.id} #{e}"
        Log.error "#{e}: #{e.backtrace.join("\n")}"
      end
    end

    def update_balances
      @accounts.values.each do |ex|
        unless ex.respond_to?(:get_balances)
          raise "ACCOUNT_ID:#{ex.account_id} Exchange #{ex.driver} doesn't support get_balances".red
        end
        begin
          Log.info "ACCOUNT_ID:#{ex.account_id} Fetching balances on #{ex.driver}"
          ex.fetch_balances
        rescue StandardError => e
          Log.error("ACCOUNT_ID:#{ex.account_id} Fetching balances on #{ex.driver} failed")
        end
      end
    end

    def update_orderbooks(strategy)
      strategy.sources.each do |ex|
        Arke::Log.debug "ID:#{strategy.id} Update #{ex.driver} #{ex.market} orderbook"
        ex.update_orderbook
      end
    end

    def execute_strategy(strategy)
      desired_orderbook = strategy.strategy.call

      strategy.strategy.debug_infos.each do |label, data|
        ::Arke::Log.debug "#{label}: #{data}".yellow
      end if strategy.debug

      unless desired_orderbook
        Log.debug "ID:#{strategy.id} No desired orderbook returned by the strategy"
        return
      end
      Log.debug "ID:#{strategy.id} Current Orderbook\n#{strategy.target.open_orders}"
      Log.debug "ID:#{strategy.id} Desired Orderbook\n#{desired_orderbook}"
      actions = ActionScheduler.new(strategy.target.open_orders, desired_orderbook, strategy.target).schedule
      strategy.executor.push(actions)
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
            strategy.target.cancel_all_orders
            EM.stop
          end
        end.resume
      end
      @shutdown = true
    end
  end
end
