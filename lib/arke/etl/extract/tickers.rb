# frozen_string_literal: true

require 'pry'
module Arke::ETL::Extract
  class Tickers < Base
    def initialize(config)
      super
      @config = config
      @influxdb = Arke::InfluxDB.client(epoch: "s")
    end

    def start
      EM::Synchrony.add_periodic_timer(2) do
        markets = convert_markets(@config["markets"])
        result = @influxdb.query("select * from tickers where market=~#{markets} group by market order by desc limit 1")
        tickers = {}
        result.each do |ticker|
          binding.pry
          data = {}
          last = @influxdb.query("SELECT price from trades where market='#{market}' order by desc limit 1")
          values = ticker["values"].first
          data["last"] = last.blank? ? 0 : last.first["values"].first["price"]

          data["price_change_percent"] = "#{'%+.2f' % values["price_change_percent"].to_d}%"
          data["low"] = values["low"].to_d
          data["high"] = values["high"].to_d
          data["open"] = values["open"].to_d
          data["volume"] = values["volume"].to_d
          data["avg_price"] = values["avg_price"].to_d
          data["at"] = values["time"].to_d
          tickers[market.downcase] = data
        end
        ticker = ::PublicTicker.new(tickers: tickers)
        emit(ticker)
      end
    end
  end
end
