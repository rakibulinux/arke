# frozen_string_literal: true

module Arke::ETL::Extract
  class Binance
    def initialize(config)
      @config = {
        "id"     => "extract-binance",
        "driver" => "binance",
        "listen" => [],
      }.merge(config || {})
      @ex = ::Arke::Exchange::Binance.new(@config)
    end

    def mount(&callback)
      @ex.register_on_public_trade_cb(&callback) if @config["listen"].include?("public_trades")
      @ex.register_on_private_trade_cb(&callback) if @config["listen"].include?("private_trades")
      @ex.register_on_created_order(&callback) if @config["listen"].include?("created_order")
      @ex.register_on_deleted_order(&callback) if @config["listen"].include?("deleted_order")
    end

    def start
      @ex.ws_connect_public
    end
  end
end
