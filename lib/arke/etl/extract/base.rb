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
  end
end
