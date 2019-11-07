# frozen_string_literal: true

module Arke::Strategy
  # * create random market orders
  # * the order amount is randomly from the min amount of the market to 2 times the min amount
  class Ohcltrades < Microtrades
    #
    # 1. Get fresh KLine 5m for source and target
    # 2. On first trade on a 5m period it should match the closer order from source open price O
    # 3. Compare HL from both sources (including spread), the side most far from current should be choosen
    # 4. The last minute of the period we should focus on matching the close price P
    #
    def get_side
      

    end
  end
end
