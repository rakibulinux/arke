class Ticker < ApplicationRecord
  belongs_to :market, required: true

  validates :mid, :bid, :ask, :last,
            :low, :high, :volume, numericality: { greater_than_or_equal_to: 0 }

  validates :mid, :bid, :ask, :last, 
            :low, :high, :volume, presence: true
end
