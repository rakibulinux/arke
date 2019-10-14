# frozen_string_literal: true

class Balance < ApplicationRecord
  belongs_to :account
  CURRENCY_NAME = %w(eth usd btc).freeze
  validates :currency, inclusion: { in: CURRENCY_NAME }
  validates :amount,
            :available,
            :locked, numericality: { greater_than_or_equal_to: 0 }
end
