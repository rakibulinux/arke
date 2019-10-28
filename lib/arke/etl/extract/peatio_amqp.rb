# frozen_string_literal: true

module Arke::ETL::Extract
  class PeatioAMQP < Base
    def initialize(config)
      super
      @ex_name = config["exchange"] || "peatio.events.ranger"
      @queue_name = config["queue_name"] || "etl.extract.amqp"
      @events = config["events"] || []
      Arke::Log.warn("Extract::PeatioAMQP initialized without events to be listen") if @events.empty?
      raise "Extract::PeatioAMQP configuration error: events must be an array" unless @events.is_a?(Array)
    end

    def process(_type, id, _event, payload)
      data = JSON.parse(payload)
      Array(data["trades"]).each do |t|
        trade = ::Arke::PublicTrade.new(t["tid"], id, t["taker_type"].to_sym, t["amount"], t["price"], t["date"] * 1000)
        emit(trade)
      end
    end

    def on_event(delivery_info, _metadata, payload)
      routing_key = delivery_info.routing_key
      type, id, event = routing_key.split(".")

      @events.each do |filter|
        if (filter["type"].nil? || filter["type"] == type) &&
          (filter["id"].nil? || filter["id"] == id) &&
          (filter["event"].nil? || filter["event"] == event)
          return process(type, id, event, payload)
        end
      end
    end

    def start
      @client = Peatio::MQ::Events::RangerEvents.new
      @client.exchange_name = @ex_name
      exchange = @client.connect!

      Peatio::MQ::Client
        .channel
        .queue(@queue_name, durable: false, auto_delete: true)
        .bind(exchange, routing_key: "#").subscribe(&method(:on_event))
    end
  end
end
