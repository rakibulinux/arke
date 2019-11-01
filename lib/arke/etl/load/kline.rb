# frozen_string_literal: true

module Arke::ETL::Load
  class Kline
    def initialize(config)
      @config = config
    end

    def call(object)
      Peatio::MQ::Events.publish("public", object[0], object[1], object[2])
    end
  end
end
