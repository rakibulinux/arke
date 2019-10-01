# frozen_string_literal: true

module Arke
  Trade = Struct.new(:id, :market, :type, :volume, :price, :order_id)
end
