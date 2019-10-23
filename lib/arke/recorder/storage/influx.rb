# frozen_string_literal: true

module Arke::Recorder::Storage
  class Influx
    def initialize(config)
      @config = config
      @output = config["storage"]["output"]
      @client = Arke::InfluxDB.client(async: true)
      @measurment = "trade"
      @time_precision = "ms"
    end

    def on_trade(trade)
      data = {
        values:
                   {
                     price:  trade.price.to_d,
                     volume: trade.volume.to_d,
                     type:   trade.type.to_s
                   },
        tags:
                   {
                     exchange: @config["exchanges"].first["driver"],
                     market:   trade.market.downcase,
                   },
        timestamp: trade.created_at
      }

      @client.write_point(@measurment, data, @time_precision)
    end
  end
end
