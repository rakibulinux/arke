class Market < ApplicationRecord
  belongs_to :exchange

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
end
