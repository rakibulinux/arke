module Arke::Strategy
  class Example1 < Strategy1
    def initialize(sources, target, config, executor)
      super
      Arke::Log.warn "Strategy name 'example1' deprecated in favor of 'strategy1'"
    end
  end
end
