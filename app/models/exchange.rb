# frozen_string_literal: true

class Exchange < ApplicationRecord

  EXCHANGE_NAMES = %w[base binance bitfaker bitfinex hitbtc huobi kraken luno okex rubykube].freeze
  validates :name, inclusion: {in: EXCHANGE_NAMES}
  validates :url,
            :rest,
            format: {with: URI.regexp(%w[http https])}
  validates :ws, format: {with: URI.regexp(%w[ws wss])}
  validates :rate, numericality: {greater_than_or_equal_to: 0}
end
