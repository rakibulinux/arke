module Arke::Helpers
  module Splitter
    SplitterAlgo = %w{constant linear logarithmic}

    def combine(side, a, b)
      side == :asks ? a + b : a - b
    end

    def split_constant(side, best_price, count, opts = {})
      step_size = opts[:step_size].to_f
      raise "missing step_size option" if step_size == 0
      result = [combine(side, best_price, step_size)]
      (count-1).times do
        price = combine(side, result.last, step_size)
        result << price if price > 0
      end
      result
    end

    def split_linear(side, best_price, count, opts = {})
      raise "missing last_price option" unless opts[:last_price]
      step = combine(side, 0, opts[:last_price] - best_price) / count
      raise "illegal range (best_price > last_price)" if step < 0
      result = []
      count.times do |i|
        price = combine(side, best_price, (i + 1) * step)
        result << price if price > 0
      end
      return result
    end

    def split_logarithmic(side, best_price, count, opts = {})
      raise "missing last_price option" unless opts[:last_price]
      n = combine(side, 0, opts[:last_price] - best_price)
      result = []
      split_linear(:asks, 0, count, last_price: n).each do |i|
        if i == n
          break
        end
        result << combine(side, best_price, n - n * (Math::log(n-i) / Math::log(n)))
      end
      result
    end

  end
end
