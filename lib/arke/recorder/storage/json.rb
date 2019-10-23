# frozen_string_literal: true

module Arke::Recorder::Storage
  class Json
    def initialize(config)
      @output = config["storage"]["output"]
    end

    def on_trade(trade)
      pp trade
    end
  end
end
