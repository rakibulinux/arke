class Trade < ApplicationRecord
  belongs_to :account, required: true
  belongs_to :market, required: true

  validates :price, :side, :amount,
            :fee, numericality: { greater_than_or_equal_to: 0 }

  validates :tid, :side, :price, 
            :amount, :fee, presence: true

  validates :tid, uniqueness: { case_sensitive: true}

end
