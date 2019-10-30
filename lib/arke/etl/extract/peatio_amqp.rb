# frozen_string_literal: true

module Arke::ETL::Extract
  class PeatioAMQP < Base
    def initialize(config)
      super
      @ex_name = config["exchange"] || "peatio.trade"
      @queue_name = config["queue_name"] || "etl.extract.amqp"
      @events = config["events"] || []
      Arke::Log.warn("Extract::PeatioAMQP initialized without events to be listen") if @events.empty?
      raise "Extract::PeatioAMQP configuration error: events must be an array" unless @events.is_a?(Array)
    end

    def process(_type, id, _event, payload)
      data = JSON.parse(payload)
      trade = ::PublicTrade.new(
        id: data["id"],
        exchange: "peatio",
        market: data["market_id"],
        taker_type: data["taker_type"],
        amount: data["amount"],
        price: data["price"],
        total: (data["total"]).to_d,
        created_at: Time.parse(data["created_at"]).to_i * 1000
      )
      emit(trade)
    end

    def on_event(delivery_info, _metadata, payload)
      routing_key = delivery_info.routing_key
      type, id, event = routing_key.split(".")

      return process(type, id, event, payload)

      # @events.each do |filter|
      #   binding.pry
      #   if (filter["type"].nil? || filter["type"] == type) &&
      #     (filter["id"].nil? || filter["id"] == id) &&
      #     (filter["event"].nil? || filter["event"] == event)
      #   end
      # end
    end

    def start
      Peatio::MQ::Client.new
      Peatio::MQ::Client.connect!
      Peatio::MQ::Client.create_channel!
      exchange = Peatio::MQ::Client.channel.headers("peatio.trade")

      Peatio::MQ::Client
        .channel
        .queue(@queue_name, durable: false, auto_delete: true)
        .bind(exchange, routing_key: "#").subscribe(&method(:on_event))
    end
  end
end
