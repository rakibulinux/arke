# frozen_string_literal: true

module Arke::ETL::Extract
  class PeatioAMQP < AMQP
    def initialize(config)
      super
      @queue_name = config["queue_name"] || "etl.extract.peatio_amqp"
    end

    def process(_type, _id, _event, payload)
      data = JSON.parse(payload)
      trade = ::PublicTrade.new(
        id:         data["id"],
        exchange:   "peatio",
        market:     data["market_id"],
        taker_type: data["taker_type"],
        amount:     data["amount"],
        price:      data["price"],
        total:      (data["total"]).to_d,
        created_at: Time.parse(data["created_at"]).to_i * 1000
      )
      emit(trade)
    end
  end
end
