# frozen_string_literal: true

module Arke::Helpers
  module Splitter
    def combine(side, a, b)
      side == :asks ? a + b : a - b
    end

    def split_constant(side, best_price, count, opts={})
      step_size = opts[:step_size].to_f
      raise "missing step_size option" if step_size.zero?
      result = []
      count.times do
        price = combine(side, result.last || best_price, step_size)
        result << price if price.positive?
      end
      result
    end

    def split_linear(side, best_price, count, opts={})
      raise "missing last_price option" unless opts[:last_price]

      step = combine(side, 0, opts[:last_price] - best_price) / count
      raise "illegal range (best_price > last_price)" if step.negative?

      result = []
      count.times do |i|
        price = combine(side, best_price, (i + 1) * step)
        result << price if price.positive?
      end
      result
    end

    def split_logarithmic(side, best_price, count, opts={})
      raise "missing last_price option" unless opts[:last_price]

      n = combine(side, 0, opts[:last_price] - best_price)
      result = []
      split_linear(:asks, 0, count, last_price: n).each do |i|
        break if i == n

        result << combine(side, best_price, n - n * (Math.log(n - i) / Math.log(n)))
      end
      result
    end
  end
end
