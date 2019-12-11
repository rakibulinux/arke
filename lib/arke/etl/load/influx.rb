# frozen_string_literal: true

module Arke::ETL::Load
  class Influx
    def initialize(config)
      @config = config
      @client = Arke::InfluxDB.client(async: true)
    end

    def call(object)
      ::Arke::Log.info "Writing trade from #{object} to InfluxDB"
      @client.write_point(@config["measurment"], object.build_data, "ms")
    end
  end
end
