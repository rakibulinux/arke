# frozen_string_literal: true

module Arke::ETL::Extract
  class Tickers < Base
    def initialize(config)
      super
      @config = config
      @influxdb = Arke::InfluxDB.client(epoch: "s")
    end

    def start
      EM::Synchrony.add_periodic_timer(5) do
        @influxdb.query("SELECT MAX(price) AS high, MIN(price) AS low, LAST(price) as last, FIRST(price) AS open, MEAN(price) AS avg_price, SUM(amount) AS volume, (LAST(price) - FIRST(price)) / FIRST(price) * 100 AS price_change_percent INTO tickers FROM trades WHERE time > now() - 24h GROUP BY market")

        result = @influxdb.query("select * from tickers group by market order by desc limit 1")
        tickers = {}
        @config["markets"].each do |market|
          data = {}
          last = @influxdb.query("SELECT price from trades where market='#{market.downcase}' order by desc limit 1")
          t = result.find {|t| t["tags"]["market"] == market.downcase }
          values = t.present? ? t["values"].first : {}
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
