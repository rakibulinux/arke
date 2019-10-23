# frozen_string_literal: true

module Arke
  Trade = Struct.new(:id, :market, :type, :volume, :price, :order_id)
  PublicTrade = Struct.new(:id, :market, :type, :volume, :price, :created_at)
end
