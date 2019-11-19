# frozen_string_literal: true

module Arke::Helpers
  module Spread
    def apply_spread(side, price, spread)
      mult = 1 + (side == :sell ? spread : -spread)
      price * mult
    end
  end
end
