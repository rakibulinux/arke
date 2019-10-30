class PublicTrade
  include ActiveModel::Model

  attr_accessor :id
  attr_accessor :market
  attr_accessor :exchange
  attr_accessor :taker_type
  attr_accessor :amount
  attr_accessor :price
  attr_accessor :total
  attr_accessor :created_at

  validates :id, :market, :taker_type, :amount, :price,
            :total, :created_at, presence: true

  def build_data
    {
      values:
                 {
                   id:         id,
                   price:      price.to_d,
                   amount:     amount.to_d,
                   total:      total,
                   taker_type: taker_type.to_s
                 },
      tags:
                 {
                   exchange: exchange,
                   market:   market.downcase,
                 },
      timestamp: created_at
    }
  end
end
