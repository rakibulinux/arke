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

    def convert(*obj)
      raise "Load::AMQP does not support #{obj.class} type" unless obj.is_a? Array

      data = obj[0]
      case data
      when ::PublicTrade
        trade = {
          "tid"        => data.id,
          "taker_type" => data.taker_type.to_s,
          "date"       => (data.created_at / 1000).to_i,
          "price"      => data.price.to_s,
          "amount"     => data.amount.to_s
        }
        return ["public", data.market.downcase, "trades", {"trades" => [trade]}]
      when ::Kline
        kline = [data.created_at, data.open, data.high, data.low, data.close, data.volume]
        return ["public", data.market.downcase, data.period, kline]
      when ::PublicTicker
        return ["public", "global", "tickers", data.tickers]
      when String
        return obj
      end
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
