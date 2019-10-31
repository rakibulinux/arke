# frozen_string_literal: true

module Arke::ETL::Transform
  class Base
    attr_reader :id

    def initialize(config)
      @config = config
      @id = config["id"] || self.class.to_s.split("::").last.downcase
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

    def call(_object)
      raise "call method missing in #{self.class}"
    end
  end
end
