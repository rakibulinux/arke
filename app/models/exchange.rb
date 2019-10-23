# frozen_string_literal: true
class Exchange < ApplicationRecord

  EXCHANGE_NAMES = %w[opendax binance bitfaker bitfinex hitbtc huobi kraken luno okex rubykube].freeze
  VALID_SCHEMAS = %w[http https ws wss].freeze
  validates :name, inclusion: {in: EXCHANGE_NAMES}
  validates :url, :rest, :ws, presence: true
  validates_each :url, :rest, :ws do |record, attr, value|
    record.errors.add(:base, "invalid #{attr}") if record.invalid_url(value)
  end
  validates :rate, numericality: {greater_than_or_equal_to: 0}

  def invalid_url(value)
    url = URI.parse(value)
    url.blank? || url.host.blank? || !url.scheme.in?(VALID_SCHEMAS)
    rescue URI::InvalidURIError
    true
  end
end
