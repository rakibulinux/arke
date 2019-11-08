# frozen_string_literal: true

module Arke::ETL::Load
  class AMQP
    def initialize(config)
      @ex_name = config["exchange"] || "peatio.events.ranger"
    end

    def start
      Peatio::MQ::Client.new
      Peatio::MQ::Client.connect!
      channel = Peatio::MQ::Client.create_channel!
      @ex = channel.topic(@ex_name)
    end

    def convert(type, id, event, payload)
      [type, id, event, payload]
    end

    def call(*args)
      type, id, event, data = convert(*args)
      routing_key = [type, id, event].join(".")
      serialized_data = JSON.dump(data)
      @ex.publish(serialized_data, routing_key: routing_key)
      Arke::Log.debug { "Load::AMQP publish #{routing_key}: #{serialized_data}" }
    end
  end
end
