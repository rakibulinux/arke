# frozen_string_literal: true

module Arke::ETL::Extract
  class PeatioAMQP < AMQP
    def initialize(config)
      super
      @queue_name = config["queue_name"] || "etl.extract.peatio_amqp"
    end

    def process(_type, id, _event, payload)
      data = JSON.parse(payload)["trades"].first
      trade = ::Arke::PublicTrade.new
      trade.id = data["tid"]
      trade.market = id
      trade.exchange = "peatio"
      trade.taker_type = data["taker_type"]
      trade.amount = data["amount"]
      trade.price = data["price"]
      trade.total = trade.total
      trade.created_at = data["date"] * 1000
      emit(trade)
    end
  end
end
