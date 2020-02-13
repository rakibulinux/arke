# frozen_string_literal: true

require "arke/strategy/base"
require "arke/strategy/copy"

module Arke
  # Strategy module, contains Strategy types implementation
  module Strategy
    # Fabric method, creates proper Exchange instance
    # * takes +config+ (hash) and passes to +Strategy+ initializer
    def self.create(sources, target, config, reactor)
      strategy_class(config["type"]).new(sources, target, config, reactor)
    end

    # Takes +type+ - +String+
    # * Resolves correct Strategy class by it's type
    def self.strategy_class(type)
      begin
        Arke::Strategy.const_get(type.split(/[-_ ]/).map(&:capitalize).join)
      rescue NameError => e
        raise "Unknown strategy type #{type}"
      end
    end
  end
end
