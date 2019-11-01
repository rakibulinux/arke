# frozen_string_literal: true

module Arke::ETL::Extract
  class Kline < Base
    POINT_PERIODS = %w[1m 5m 15m 30m 1h 2h 4h 6h 12h 1d 3d].freeze

    def initialize(config)
      super
      @config = config
      @influxdb = Arke::InfluxDB.client(epoch: "s")
    end

    def start
      EM::Synchrony.add_periodic_timer(5) do
        POINT_PERIODS.each do |period|
          markets = convert_markets(@config["markets"])
          if markets.present?
            result = @influxdb.query("select * from candles_#{period} where market=~#{markets} group by market order by desc limit 1")
          else
            result = @influxdb.query("select * from candles_#{period} group by market order by desc limit 1")
          end

          result.map do |c|
            values = c["values"].first
            kline = ::Kline.new(
              market: c["tags"]["market"],
              period: "kline-#{period}",
              open: values["open"],
              high: values["high"],
              low: values["low"],
              close: values["close"],
              volume: values["volume"],
              created_at: values["time"]
            )

            emit(kline)
          end
        end
      end
    end
  end
end
