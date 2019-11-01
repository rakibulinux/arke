# frozen_string_literal: true

module Arke::ETL::Extract
  class Base
    def initialize(_config)
      @callbacks = []
    end

    def mount(&callback)
      @callbacks << callback
    end

    def emit(*args)
      @callbacks.each do |cb|
        cb.call(*args)
      end
    end

    def start
      raise "start method missing in #{self.class}"
    end

    def convert_markets(markets)
      output = "/"
      markets.each do |market|
        output += market.downcase
        unless market == markets.last
          output += "|"
        end
      end
      output += "/"
    end
  end
end
