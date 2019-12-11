# frozen_string_literal: true

module Arke::Command
  class Order < Clamp::Command
    include Arke::Helpers::Commands
    option "--config", "FILE_PATH", "Strategies config file", default: "config/strategies.yml"
    option "--dry", :flag, "do not send the order"
    option "--wait-time", "SECONDS", "Keep connection open to receive transaction feedback", default: "1"

    parameter "ACCOUNT_ID", "market id on the target platform", attribute_name: :account_id
    parameter "MARKET_ID", "market id on the target platform", attribute_name: :market_id
    parameter "SIDE", "buy or sell", attribute_name: :side
    parameter "PRICE", "price", attribute_name: :price
    parameter "AMOUNT", "amount", attribute_name: :amount
    def execute
      logger = ::Arke::Log
      logger.level = Logger::DEBUG
      acc_config = accounts_configs.find {|a| a["id"] == account_id }
      raise "market #{market_id} not found" unless acc_config

      order = ::Arke::Order.new(market_id, price, amount, side)
      logger.info order.inspect
      return if dry?

      EM.synchrony do
        ex = Arke::Exchange.create(acc_config)
        response = ex.create_order(order)
        logger.info { "Response: #{response}" }
        EM::Synchrony.add_timer(wait_time.to_f) { EM.stop }
      end
    end
  end
end
