class Market < ApplicationRecord
  belongs_to :exchange
  has_one :ticker

  validates :exchange_id,
            :name,
            :base,
            :quote,
            :state,
            presence: true
  
  validates :base_precision,
            :quote_precision,
            :min_amount,
            :min_price,
            numericality: { greater_than_or_equal_to: 0, only_integer: true }
  
  validate  :exchange_market_uniqueness

  def to_h
    {
      "exchange_id" => :id,
      "name" => name,
      "base" => base,
      "quote" => quote,
      "base_precision" => base_precision,
      "quote_precision" => quote_precision,
      "min_price" => min_amount,
      "min_amount" => min_amount,
    }
  end

  private

  def exchange_market_uniqueness
    if Market.where(exchange_id: exchange_id, name: name).exists?
      errors.add(:base, :exchange_market_exists, message: 'exchange market already exists')
    end
  end
end
