require "arke/strategy/base"
require "arke/strategy/copy"

module Arke
  # Strategy module, contains Strategy types implementation
  module Strategy
    # Fabric method, creates proper Exchange instance
    # * takes +config+ (hash) and passes to +Strategy+ initializer
    def self.create(sources, target, config, executor, reactor)
      strategy_class(config["type"]).new(sources, target, config, executor, reactor)
    end

    # Takes +type+ - +String+
    # * Resolves correct Strategy class by it's type
    def self.strategy_class(type)
      Arke::Strategy.const_get(type.capitalize)
    end
  end
end
