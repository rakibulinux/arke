# frozen_string_literal: true

module Arke::Helpers
  module Splitter
    def combine(side, a, b)
      (side == :asks ? a + b : a - b).to_d
    end

    def split_constant(side, best_price, count, opts={})
      step_size = opts[:step_size].to_d
      raise "missing step_size option" if step_size.zero?

      result = []
      count.times do
        value = combine(side, result.last || best_price, step_size)
        result << value if value.positive?
      end
      result
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

    def split_constant_pp(side, best_price, count, opts={})
      split_constant(side, best_price, count, opts).map {|value| ::Arke::PricePoint.new(value) }
    end
  end
end
