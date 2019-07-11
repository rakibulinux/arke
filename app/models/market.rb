class Market < ApplicationRecord
  belongs_to :exchange
  has_one :ticker

  validates :name, presence: true
  validate :exchange_market_uniqueness

  def to_h
    {
      "id" => name,
      "base" => base,
      "quote" => quote,
      "base_precision" => base_precision,
      "quote_precision" => base_precision,
      "min_ask_amount" => min_ask_amount,
      "min_bid_amount" => min_bid_amount,
    }
  end

  private

  def exchange_market_uniqueness
    if Market.where(exchange_id: exchange_id, name: name).exists?
      errors.add(:base, :exchange_market_exists, message: 'exchange market already exists')
    end
  end
end
