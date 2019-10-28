# frozen_string_literal: true

module Arke::ETL::Transform
  class Base
    attr_reader :id

    def initialize(config)
      @config = config
      @id = config["id"] || self.class.to_s.split("::").last.downcase
    end

    def mount(&callback)
      Arke::Log.warn "a callback was already set on #{self.class}" if @callback
      @callback = callback
    end

    def emit(*args)
      @callback.call(*args)
    end

    def call(_object)
      raise "call method missing in #{self.class}"
    end
  end
end
