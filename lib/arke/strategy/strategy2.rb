module Arke::Strategy
  class Strategy2 < Base
    def initialize(sources, target, config, executor, reactor)
      super
      params = @config["params"] || {}
      @levels_size = params["levels_size"].to_f
      @levels_count = params["levels_count"].to_i
      @spread_bids = params["spread_bids"].to_f
      @spread_asks = params["spread_asks"].to_f
      @limit_asks_base = params["limit_asks_base"].to_f
      @limit_bids_base = params["limit_bids_base"].to_f
      @side_asks = %w{asks both}.include?(@side)
      @side_bids = %w{bids both}.include?(@side)
      Arke::Log.info "min order back amount: #{source.min_order_back_amount}"
      Arke::Log.info "Initializing #{self.class} strategy with order_back #{@enable_orderback ? "enabled": "disabled"}"
    end

    def call
      raise "This strategy supports only one exchange source" if sources.size > 1
      
    end
  end
end
