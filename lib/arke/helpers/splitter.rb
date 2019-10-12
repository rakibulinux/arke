# frozen_string_literal: true

module Arke::Helpers
  module Splitter
    def split_constant(side, best_price, count, opts={})
      step_size = opts[:step_size].to_f

      raise ArgumentError("Missing step_size") if step_size.zero?

      from = side == :asks ? best_price : (best_price + count * step_size)
      to   = side == :asks ? (best_price - count * step_size) : best_price
      from.step(by: step_size, to: to).to_a.select(&:positive?)
    end
  end
end
