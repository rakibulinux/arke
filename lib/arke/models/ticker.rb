# frozen_string_literal: true

module Arke
  # TODO: Rewrite this
  Tickers = Struct.new(:data) do
    def for_notify(res={})
      data.each do |key, value|
        value[:price_change_percent] = "#{'%+.2f' % value[:price_change_percent].to_d}%"
        value.merge! value.except(:at).transform_values!(&:to_s)
        res[key] = value
      end

      res
    end
  end

  Ticker = Struct.new(:open, :low, :high, :last, :volume, :avg_price, :price_change_percent, :time, :market) do
    def build_data
      {
        values:
                   {
                     open:                 open,
                     low:                  low,
                     high:                 high,
                     last:                 last,
                     volume:               volume,
                     avg_price:            avg_price,
                     price_change_percent: price_change_percent,

                   },
        tags:
                   {
                     market: market.downcase,
                   },
        timestamp: time * 1000
      }
    end
  end
end
