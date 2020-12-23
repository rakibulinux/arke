# frozen_string_literal: true

module Arke::Helpers
  module PricePoints
    def combine(side, a, b)
      (side == :asks ? a + b : a - b).to_d
    end

    def price_step(level_i, levels_price_func, levels_price_step)
      case levels_price_func
      when "constant"
        levels_price_step
      when "linear"
        (level_i + 1) * levels_price_step
      when "exp"
        Math.exp(level_i) * levels_price_step
      else
        raise "Invalid levels_price_func #{levels_price_func}"
      end
    end

    def price_points(side, price_start, levels_count, levels_price_func, levels_price_step)
      raise "Invalid levels_count" if levels_count.nil?
      raise "Invalid side #{side}" unless %i[bids asks].include?(side)
      return nil if price_start.nil?

      points = []
      last_price = price_start
      levels_count.times do |i|
        price_delta = price_step(i, levels_price_func, levels_price_step)
        price = combine(side, last_price, price_delta)
        points << ::Arke::PricePoint.new(price)
        last_price = price
      end
      points
    end

    def split_linear(side, best_value, count, opts={})
      raise "missing last_value option" unless opts[:last_value]

      step = combine(side, 0, opts[:last_value] - best_value).to_f / count
      raise "illegal range (best_value > last_value)" if step.negative?

      result = []
      count.times do |i|
        value = combine(side, best_value, (i + 1) * step)
        result << value if value.positive?
      end
      result
    end

  end
end
