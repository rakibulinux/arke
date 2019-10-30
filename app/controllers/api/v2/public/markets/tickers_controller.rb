# frozen_string_literal: true
require 'arke/influxdb'
module Api
  module V2
    module Public
      module Markets
        class TickersController < BaseController

          def index

            influxdb = Arke::InfluxDB.client(epoch: "s")
            result = influxdb.query("select * from tickers where time > now() - 1d")
            result = result.first["values"] if result.present?

            data = {}
            result.map do |ticker|
              # { fthusd: { "at":1572018804,"ticker":{"buy":"172.0","sell":"173.0","low":"172.0",
              # "high":"172.0","open":173.35,"last":"172.0","volume":"0.06","avg_price":"172.0","price_change_percent":"-0.78%","vol":"0.06"}}
              market = ticker["market"]
              data[market] = {"at" => ticker["time"], "ticker" => { low: ticker["low"], high: ticker["high"], open: ticker["open"], last: ticker["last"], volume: ticker["volume"], avg_price: ticker["avg_price"], "price_change_percent": "#{'%+.2f' % ticker["price_change_percent"]}%"}}
            end

            json_response(data, 200)
          end
        end
      end
    end
  end
end
