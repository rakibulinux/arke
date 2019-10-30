# frozen_string_literal: true
require 'arke/influxdb'

module Api
  module V2
    module Public
      module Markets
        class KlineController < BaseController
          AVAILABLE_POINT_PERIODS = %w[1 5 15 30 60 120 240 360 720 1440 4320 10080].freeze

          HUMANIZED_POINT_PERIODS = {
            1 => "1m", 5 => "5m", 15 => "15m", 30 => "30m",                   # minutes
            60 => "1h", 120 => "2h", 240 => "4h", 360 => "6h", 720 => "12h",  # hours
            1440 => "1d", 4320 => "3d",                                       # days
            10_080 => "1w"                                                    # weeks
          }.freeze

          def index

            unless params["period"].in?(AVAILABLE_POINT_PERIODS)
              error_response("public.k_line.invalid_period", 422)
              return
            end

            unless /\A\d+\z/.match(params["time_from"]) && /\A\d+\z/.match(params["time_to"])
              error_response("public.k_line.non_integer_time", 422)
              return
            end

            market = params["market"]
            period = HUMANIZED_POINT_PERIODS[params["period"].to_i]
            # to ns
            time_from = params["time_from"].to_i * 1_000_000_000
            time_to = params["time_to"].to_i * 1_000_000_000

            # InfluxDB will return time in seconds
            influxdb = Arke::InfluxDB.client(epoch: "s")

            result = influxdb.query("select * from candles_#{period} where market='#{market}' and time >= #{time_from} and time < #{time_to}")

            result = result.first["values"] if result.present?

            response = result.map do |value|
              [value["time"], value["open"], value["high"], value["low"], value["close"], value["volume"]]
            end

            json_response(response, 200)
          end
        end
      end
    end
  end
end
