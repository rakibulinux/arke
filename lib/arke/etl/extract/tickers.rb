# frozen_string_literal: true

require "pry"
module Arke::ETL::Extract
  class Tickers < Base
    ZERO = "0.0".to_d

    def initialize(config)
      super
      @config = config
      @influxdb = Arke::InfluxDB.client(epoch: "s")
    end

    def start
      EM::Synchrony.add_periodic_timer(5) do
        result = @influxdb.query("SELECT MAX(price) AS high, MIN(price) AS low, LAST(price) as last, FIRST(price) AS open, MEAN(price) AS avg_price, SUM(total) AS volume, (LAST(price) - FIRST(price)) / FIRST(price) * 100 AS price_change_percent FROM trades WHERE time > now() - 24h GROUP BY market")

        tickers = @config["markets"].each_with_object({}) do |market, tickers|
          record = result.find {|t| t["tags"]["market"] == market.downcase }
          ticker = if record.present?
                     res = record["values"].first.symbolize_keys
                     res[:at] = res.delete :time
                     res
                   else
                     last = @influxdb.query("SELECT price from trades where market='#{market.downcase}' order by desc limit 1")
                     default_ticker.merge(last: last.present? ? last.first["values"].first["price"] : 0.0)
                   end
          tickers[market.downcase] = ticker
        end
        tickers = Arke::Tickers.new(tickers)
        emit(tickers)
      end
    end

    def default_ticker
      {open: ZERO, low: ZERO, high: ZERO, volume: ZERO, avg_price: ZERO, price_change_percent: 0.0, at: Time.now.to_i}
    end
  end
end
