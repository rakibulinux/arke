# frozen_string_literal: true

module Arke::ETL::Load
    class TickersWriter
      def initialize(_config); end
  
      def call(*args)
        @influxdb.query("SELECT MAX(price) AS high, MIN(price) AS low,LAST(price) as last,"\
                        "FIRST(price) AS open, MEAN(price) AS avg_price, SUM(amount) AS volume,"\
                        "(LAST(price) - FIRST(price)) / FIRST(price) * 100 AS price_change_percent "\
                        "INTO tickers FROM trades WHERE time > now() - 24h GROUP BY market")
      end
    end
  end
  