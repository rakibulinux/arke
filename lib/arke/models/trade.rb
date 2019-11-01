# frozen_string_literal: true

module Arke
  Trade = Struct.new(:id, :market, :type, :volume, :price, :total, :order_id)
  PublicTrade = Struct.new(:id, :market, :exchange, :taker_type, :amount, :price, :total, :created_at) do

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

    def total
      amount.to_d * price.to_d
    end
  end
end
