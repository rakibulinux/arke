# frozen_string_literal: true

module Arke::Helpers::Orderbook
  def better_or_equal(side, a, b)
    a == b || better(side, a, b)
  end

  def better(side, a, b)
    side == :buy ? a > b : a < b
  end

  def opposite_side(side)
    side.to_s == "buy" ? :sell : :buy
  end
end
