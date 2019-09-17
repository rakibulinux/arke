# frozen_string_literal: true

module Arke::Strategy
  class Strategy2 < Base
    REFRESH_TIMES = [
      2, 5, 7, 11, 13, 17, 19, 23, 29, 37, 41, 43, 47, 53, 59, 61, 67, 71, 73, 79, 83, 89, 97, 101, 103, 107, 109, 113,
      127, 131, 137, 139, 149, 151, 157, 163, 167, 173, 179, 181, 191, 193, 197, 199
    ].freeze

    # TODO: strategy2 breaks the microtrades because it doesn't contains any open_orders object
    # SOLUTION 1: we can generate an aggregated open_orders object on demand

    def initialize(sources, target, config, executor, reactor)
      super
      return unless @enabled

      params = config["params"] || {}
      @levels_size = params["levels_size"].to_f
      @levels_count = params["levels_count"].to_i
      @spread_bids = params["spread_bids"].to_f
      @spread_asks = params["spread_asks"].to_f
      @limit_asks_base = params["limit_asks_base"].to_f
      @limit_bids_base = params["limit_bids_base"].to_f
      @side_asks = %w[asks both].include?(@side)
      @side_bids = %w[bids both].include?(@side)
      Arke::Log.info "min order back amount: #{source.min_order_back_amount}"
      Arke::Log.info "Initializing #{self.class} strategy with order_back #{@enable_orderback ? 'enabled' : 'disabled'}"
      @reactor = reactor
      @executor = executor
      init_sub_strategies
    end

    def init_sub_strategies
      # TODO: the refresh time of the level 1 must not be lower than target delay / 2
      @levels_count.times do |i|
        config_id = "#{id}-#{i}"
        config = {
          "type"    => "strategy1",
          "id"      => config_id,
          "period"  => period * REFRESH_TIMES[i],
          "enabled" => @enabled,
          "params"  => {
            "levels_size"     => @levels_size,
            "levels_count"    => 1,
            # TODO: add "levels_offset" to strategy1
            "spread_bids"     => @spread_bids,
            "spread_asks"     => @spread_asks,
            "limit_asks_base" => @limit_asks_base,
            "limit_bids_base" => @limit_bids_base,
            "side_asks"       => @side_asks,
            "side_bids"       => @side_bids,
          }
        }
        strategy = Arke::Strategy.create(sources, target, config, @executor, @reactor)
        @reactor.register_strategy(strategy, config_id, sources, target, @executor, @debug)
      end
    end

    def call
      raise "This strategy supports only one exchange source" if sources.size > 1
    end
  end
end
