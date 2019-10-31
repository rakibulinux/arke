# frozen_string_literal: true

module Arke::ETL::Transform
  class Generic < Base
    def initialize(config)
      super
      @field = config["field"]
      @apply = config["apply"]
      raise "Transform::Generic field is mandatory" unless @field
      raise "Transform::Generic apply is mandatory" unless @apply
    end

    def call(object)
      object.send(@field).send(@apply)
      emit(object)
    end
  end
end
