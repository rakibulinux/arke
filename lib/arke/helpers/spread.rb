module Arke::Helpers
  module Spread
    def apply_spread(side, price, spread)
      if side == :sell
        mult = 1 + spread
      else
        mult = 1 - spread
      end

      price * mult
    end
  end
end