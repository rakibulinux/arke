# frozen_string_literal: true

module Arke
  Trade = Struct.new(:id, :market, :type, :volume, :price, :total, :order_id)
  PublicTrade = Struct.new(:id, :market, :taker_type, :amount, :price, :total, :created_at)
end
