# frozen_string_literal: true

module Arke::Helpers::Orderbook
  def better_or_equal(side, a, b)
    side == :buy ? a >= b : a <= b
  end

  def better(side, a, b)
    side == :buy ? a > b : a < b
  end
end
