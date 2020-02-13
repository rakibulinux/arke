# frozen_string_literal: true

module Arke::Strategy
  # * create random market orders
  # * the order amount is random from the min amount of the market and up to 2 times the min amount
  class Microtrades < MicrotradesMarket; end
end
