# frozen_string_literal: true
require 'arke/influxdb'
module Api
  module V2
    module Public
      module Markets
        class TradesController < BaseController

          def index

            unless params["limit"].to_i.positive? && params["limit"].to_i <= 1000 || params["limit"].blank?
              error_response("public.k_line.invalid_limit", 422)
              return
            end

            market = params["market"]
            order_by = params.fetch("order_by", "desc")
            params["limit"] = params.fetch("limit", 1000)

            # Set chunk_size if expect large quantities of data in a response
            influxdb = Arke::InfluxDB.client(chunk_size: 1000)
            result = influxdb.query("select * from trades where market='#{market}' order by #{order_by} limit #{params["limit"]}")
            result = result.first["values"] if result.present?

            response = result.map do |value|
              value["amount"] = value["amount"].to_s
              value["price"] = value["price"].to_s
              value["total"] = value["total"].to_s
              value["created_at"] = value.delete("time")
              value.except("exchange")
            end

            json_response(paginate(response), 200)
          end
        end
      end
    end
  end
end
