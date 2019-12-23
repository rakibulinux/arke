# frozen_string_literal: true

module Arke::Fx
  class Static
    attr_reader :rate

    def initialize(config)
      @rate = config["rate"]&.to_d
      check_config
    end

    def check_config
      raise "rate missing" if rate.nil?
      raise "invalid rate" if rate <= 0
    end

    def start; end

    def apply(ob, price_levels)
      raise "FX: Rate is not ready" if rate.nil?

      fx_ob = ::Arke::Orderbook::Orderbook.new(ob.market)
      fx_price_levels = {}

      ob.book.each do |k, _v|
        ob.book[k].each do |price, amount|
          fx_ob[k][price * rate] = amount
        end
      end

      price_levels.each do |k, v|
        fx_price_levels[k] = v.map do |pl|
          ::Arke::PricePoint.new(pl.price_point * rate, pl.weighted_price)
        end
      end

      [fx_ob, fx_price_levels]
    end
  end
end
