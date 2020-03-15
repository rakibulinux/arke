# frozen_string_literal: true

module Arke
  # Exchange module, contains Exchanges drivers implementation
  module Exchange
    # Fabric method, creates proper Exchange instance
    # * takes +strategy+ (+Arke::Strategy+) and passes to Exchange initializer
    # * takes +config+ (hash) and passes to Exchange initializer
    # * takes +config+ and resolves correct Exchange class with +exchange_class+ helper
    def self.create(config)
      raise "driver is missing for account id #{config["id"]}" if config["driver"].to_s.empty?
      exchange_class(config["driver"]).new(config)
    end

    # Takes +dirver+ - +String+
    # Resolves correct Exchange class by it's name
    def self.exchange_class(driver)
      Arke::Exchange.const_get(driver.capitalize)
    end
  end
end
