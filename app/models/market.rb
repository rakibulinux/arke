# frozen_string_literal: true

class Market < ApplicationRecord
  STATES = %w[enabled disabled hidden].freeze

  belongs_to :exchange, required: true
  has_one :ticker

  validates :name, :base,
            :quote, :state, presence: true

  validates :base_precision,
            :quote_precision,
            numericality: {greater_than_or_equal_to: 0, only_integer: true}

  validates :min_amount,
            :min_price,
            numericality: {greater_than_or_equal_to: 0}

  validates :state, inclusion: {in: STATES}

  validate  :exchange_market_uniqueness
  
  private

  def exchange_market_uniqueness
    if Market.where(exchange_id: exchange_id, name: name).exists?
      errors.add(:base, :exchange_market_exists, message: "exchange market already exists")
    end
  end
end
