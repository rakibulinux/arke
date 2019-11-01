# frozen_string_literal: true

module Arke::ETL::Extract
  class PeatioAMQP < AMQP
    def initialize(config)
      super
      @queue_name = config["queue_name"] || "etl.extract.peatio_amqp"
    end

    def process(_type, id, _event, payload)
      data = JSON.parse(payload)["trades"].first
      total = (data["price"].to_d * data["amount"].to_d)
      trade = ::PublicTrade.new(
        id:         data["tid"],
        exchange:   "peatio",
        market:     id,
        taker_type: data["taker_type"],
        amount:     data["amount"],
        price:      data["price"],
        total:      total,
        created_at: data["date"] * 1000
      )
      emit(trade)
    end
  end
end
