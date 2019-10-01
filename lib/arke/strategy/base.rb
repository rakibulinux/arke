module Arke::Strategy
  # Base class for all strategies
  class Base
    attr_reader :debug_infos, :period, :period_random_delay
    attr_reader :sources, :target, :id

    Sides = %w{asks bids both}

    DefaultPeriod = 10

    def initialize(sources, target, config, executor, reactor)
      @config = config
      @id = @config["id"]
      @volume_ratio = config["volume_ratio"]
      @spread = config["spread"]
      @precision = config["precision"]
      @debug = !!config["debug"]
      @debug_infos = {}
      @period = (config["period"] || DefaultPeriod).to_f
      @period_random_delay = config["period_random_delay"]
      params = @config["params"] || {}
      @side = Sides.include?(params["side"]) ? params["side"] : "both"
      @trades = []
      @executor = executor
      @sources = sources
      @target = target
      @reactor = reactor
      Arke::Log.info "ID:#{id} ----====[ #{self.class.to_s.split('::').last} Strategy ]====----"
    end

    def delay_the_first_execute
      false
    end

    def push_debug(step_name, step_data)
      return unless @debug
      @debug_infos[step_name] = step_data
    end

    def assert_currency_found(ex, currency)
      unless ex.balance(currency)
        raise "ID:#{id} Currency #{currency} not found on #{ex.driver}".red
      end
    end

    def source
      sources.first
    end
  end
end
