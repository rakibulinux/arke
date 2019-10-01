module Arke::Strategy
  class Strategy1 < Orderback
    def initialize(sources, target, config, reactor)
      super
      Arke::Log.warn "Strategy name 'strategy1' deprecated in favor of 'orderback'"
    end
  end
end
