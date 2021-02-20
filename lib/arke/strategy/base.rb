# frozen_string_literal: true

module Arke::Strategy
  # Base class for all strategies
  class Base
    attr_accessor :timer
    attr_accessor :fx
    attr_reader :debug_infos, :period, :period_random_delay, :linked_strategy_id
    attr_reader :sources, :target, :id, :debug, :logger, :delay
    attr_reader :max_amount_per_order

    SIDES = %w[asks bids both].freeze
    DEFAULT_PERIOD = 10

    def initialize(sources, target, config, reactor)
      @logger = Arke::Log
      @config = config
      @id = @config["id"]
      @debug = config["debug"] ? true : false
      @debug_infos = {}
      @period = (config["period"] || DEFAULT_PERIOD).to_f
      @period_random_delay = config["period_random_delay"].to_f
      @delay = Array(config["delay"] || target.account.delay)
      params = @config["params"] || {}
      @linked_strategy_id = params["linked_strategy_id"]
      @side = SIDES.include?(params["side"]) ? params["side"] : "both"
      @max_amount_per_order = params["max_amount_per_order"]&.to_d
      @trades = []
      @sources = sources
      @target = target
      @reactor = reactor
      logger.info { "ID:#{id} ----====[ #{self.class.to_s.split('::').last} Strategy ]====----" }
    end

    def delay_the_first_execute
      false
    end

    def push_debug(step_name, step_data)
      return unless @debug

      @debug_infos[step_name] = step_data
    end

    def assert_currency_found(account, currency)
      raise "ID:#{id} Currency #{currency} not found on #{account.driver}".red unless account.balance(currency)
    end

    def source
      sources.first
    end
  end
end
