
require "arke/exchange"
require "arke/strategy"

module Arke
  # Main event ractor loop
  class Reactor
    # * @shutdown is a flag which controls strategy execution
    def initialize(configs)
      @shutdown = false
      init_strategies(configs)
    end

    def report_fatal(e, id)
      Arke::Log.fatal "#{e}: #{e.backtrace.join("\n")}"
      Arke::Log.fatal "ID:#{id} Strategy stopped"
    end

    def init_strategies(strategies_configs)
      @strategies = strategies_configs.map do |config|
        begin
          executor = ActionExecutor.new(config)
          sources = Array(config["sources"]).map do |ex_config|
            Arke::Exchange.create(ex_config)
          end
          target = config["target"] ? Arke::Exchange.create(config["target"]) : nil
          strategy = Arke::Strategy.create(sources, target, config, executor)
          OpenStruct.new({
            id: config["id"],
            target: target,
            sources: sources,
            executor: executor,
            strategy: strategy,
            debug: config["debug"] ? true : false,
          })
        rescue StandardError => e
          report_fatal(e, config["id"])
          nil
        end
      end.compact
    end

    def run
      EM.synchrony do
        trap("INT") { stop }

        Arke::Log.info("Starting Reactor")

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
        update_balances(strategy)
        update_orderbooks(strategy)
        execute_strategy(strategy)
      rescue StandardError
        Log.error "ID:#{strategy.id} #{$!}"
      end
    end

    def update_balances(strategy)
      (strategy.sources + Array(strategy.target)).each do |ex|
        unless ex.respond_to?(:get_balances)
          raise "ID:#{strategy.id} Exchange #{name.driver} doesn't support get_balances".red
        end
        begin
          Log.info "ID:#{strategy.id} Fetching balances on #{ex.driver}"
          ex.fetch_balances
        rescue StandardError => e
          Log.error("ID:#{strategy.id} Fetching balances on #{ex.driver} failed")
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
