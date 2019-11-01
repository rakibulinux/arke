# frozen_string_literal: true

require "influxdb"
require "erb"
module Arke
  module InfluxDB
    class << self
      def client(opts={})
        ::InfluxDB::Client.new(config.merge(opts))
      end

      def config
        yaml = ::Pathname.new("config/influxdb.yml")
        return {} unless yaml.exist?

        erb = ::ERB.new(yaml.read)
        ::YAML.load(erb.result)[ENV.fetch('RAILS_ENV', 'development')].symbolize_keys || {}
      end
    end
  end
end
