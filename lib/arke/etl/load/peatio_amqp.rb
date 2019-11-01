# frozen_string_literal: true

module Arke::ETL::Load
  class PeatioAMQP < AMQP
    def convert(obj)
      case obj
      when ::PublicTrade
        trade = {
          "tid"        => obj.id,
          "taker_type" => obj.taker_type.to_s,
          "date"       => (obj.created_at / 1000).to_i,
          "price"      => obj.price.to_s,
          "amount"     => obj.amount.to_s
        }
        return ["public", obj.market, "trades", {"trades" => [trade]}]
      when ::Kline
        kline = [obj.created_at, obj.open, obj.high, obj.low, obj.close, obj.volume]
        return ["public", obj.market.downcase, obj.period, kline]
      when ::PublicTicker
        return ["public", "global", "tickers", obj.tickers]
      end
      raise "Load::AMQP does not support #{obj.class} type"
    end
  end
end
