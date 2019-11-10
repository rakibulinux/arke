# frozen_string_literal: true

module Arke
  class PricePoint
    attr_reader :price_point
    attr_reader :weighted_price

    def initialize(price_point, weighted_price)
      @price_point = price_point.to_d
      @weighted_price = weighted_price.to_d
    end
  end
end
