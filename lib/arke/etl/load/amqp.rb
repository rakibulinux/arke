# frozen_string_literal: true

module Arke::ETL::Load
  class AMQP
    def initialize(config)
      @ex_name = config["exchange"] || "peatio.events.ranger"
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

    def convert(obj)
      case obj
      when ::Arke::PublicTrade
        trade = {
          "tid"        => obj.id,
          "taker_type" => obj.type.to_s,
          "date"       => (obj.created_at / 1000).to_i,
          "price"      => obj.price.to_s,
          "amount"     => obj.volume.to_s
        }
        return ["public", obj.market, "trades", {"trades" => [trade]}]
      end
      raise "Load::AMQP does not support #{obj.class} type"
    end

    def call(object)
      type, id, event, data = convert(object)
      Peatio::MQ::Events.publish(type, id, event, data)
    end
  end
end
