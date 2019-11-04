# frozen_string_literal: true

module Arke::ETL::Extract
  class AMQP < Base
    def initialize(config)
      super
      @ex_name = config["exchange"] || "peatio.events.ranger"
      @events = config["events"] || []
      Arke::Log.warn("Extract::AMQP initialized without events to be listen") if @events.empty?
      raise "Extract::AMQP configuration error: events must be an array" unless @events.is_a?(Array)
    end

    def process(type, id, event, payload)
      emit(type, id, event, JSON.parse(payload))
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
      Peatio::MQ::Client.new
      Peatio::MQ::Client.connect!
      channel = Peatio::MQ::Client.create_channel!
      exchange = channel.topic(@ex_name)

      @queue_name ||= "etl.extract.amqp"

      channel
        .queue(@queue_name, durable: false, auto_delete: true)
        .bind(exchange, routing_key: "#").subscribe(&method(:on_event))
    end
  end
end
