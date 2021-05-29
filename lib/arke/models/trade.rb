# frozen_string_literal: true

module Arke
  Trade = Struct.new(:id, :market, :type, :volume, :price, :total, :order_id)
  PriceLevel = Struct.new(:price, :amount)

  PublicTrade = Struct.new(:id, :market, :exchange, :taker_type, :amount, :price, :total, :created_at) do
    def total
      amount.to_d * price.to_d
    end
  end
end
