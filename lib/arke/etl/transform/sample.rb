# frozen_string_literal: true

module Arke::ETL::Transform
  class Sample < Base
    attr_reader :ratio

    def initialize(config)
      super
      @ratio = config["ratio"] || 1.0
      raise "Transform::Sample ratio must be a number" unless @ratio.is_a?(Numeric)
      raise "Transform::Sample ratio must be between 0 and 1" if @ratio.negative? || @ratio > 100
    end

    def call(object)
      return unless rand() <= @ratio

      emit(object)
    end
  end
end
