# frozen_string_literal: true

class Kline
  include ActiveModel::Model

  attr_accessor :market
  attr_accessor :exchange
  attr_accessor :open
  attr_accessor :high
  attr_accessor :low
  attr_accessor :close
  attr_accessor :volume
  attr_accessor :period
  attr_accessor :created_at

  validates :created_at, :market, :open, :high, :low,
            :close, :volume, presence: true

  def build_data
    {
      values:
                  {
                    low:       low.to_d,
                    high:      high.to_d,
                    open:      open.to_d,
                    last:      last.to_d,
                    volume:    volume.to_d,
                    avg_price: avg_price.to_d
                  },
      tags:
                  {
                    exchange: exchange,
                    market:   market.downcase,
                  },
      timestamp: at
    }
  end
end
