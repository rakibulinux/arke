# frozen_string_literal: true

module Arke::Command
  class Order < Clamp::Command
    class Create < Clamp::Command
      include Arke::Helpers::Commands
      option "--config", "FILE_PATH", "Strategies config file", default: "config/strategies.yml"
      option "--dry", :flag, "do not send the order"

      parameter "ACCOUNT_ID", "market id on the target platform", attribute_name: :account_id
      parameter "MARKET_ID", "market id on the target platform", attribute_name: :market_id
      parameter "SIDE", "buy or sell", attribute_name: :side
      parameter "PRICE", "price", attribute_name: :price
      parameter "AMOUNT", "amount", attribute_name: :amount
      def execute
        logger = ::Arke::Log
        logger.level = Logger::DEBUG
        acc_config = accounts_configs.find {|a| a["id"] == account_id }
        raise "account #{account_id} not found" unless acc_config

        EM.synchrony do
          ex = Arke::Exchange.create(acc_config)
          order = ::Arke::Order.new(market_id, price, amount, side)
          order.apply_requirements(ex)
          logger.info order.inspect

          unless dry?
            response = ex.create_order(order)
            logger.info { "Response: #{response.body}" }
          end

          EM.stop
        end
      end
    end

    class Cancel < Clamp::Command
      include Arke::Helpers::Commands
      option "--config", "FILE_PATH", "Strategies config file", default: "config/strategies.yml"

      parameter "ACCOUNT_ID", "market id on the target platform", attribute_name: :account_id
      parameter "ORDER_ID", "order identifier to cancel", attribute_name: :order_id
      def execute
        logger = ::Arke::Log
        logger.level = Logger::DEBUG
        acc_config = accounts_configs.find {|a| a["id"] == account_id }
        raise "account #{account_id} not found" unless acc_config

        EM.synchrony do
          ex = Arke::Exchange.create(acc_config)
          order = Struct.new(:id).new(order_id)
          response = ex.stop_order(order)
          logger.info { "Response: #{response.body}" }
          EM.stop
        end
      end
    end

    class CancelAll < Clamp::Command
      include Arke::Helpers::Commands
      option "--config", "FILE_PATH", "Strategies config file", default: "config/strategies.yml"
      option "--market", "MARKET_ID", "market id on the target platform"

      parameter "ACCOUNT_ID", "market id on the target platform", attribute_name: :account_id
      def execute
        logger = ::Arke::Log
        logger.level = Logger::DEBUG
        acc_config = accounts_configs.find {|a| a["id"] == account_id }
        raise "account #{account_id} not found" unless acc_config

        EM.synchrony do
          ex = Arke::Exchange.create(acc_config)
          response = ex.cancel_all_orders(market)
          logger.info { "Response: #{response.body}" }
          EM.stop
        end
      end
    end

    class List < Clamp::Command
      include Arke::Helpers::Commands
      option "--config", "FILE_PATH", "Strategies config file", default: "config/strategies.yml"
      option "--market", "MARKET_ID", "market id on the target platform"

      parameter "ACCOUNT_ID", "market id on the target platform", attribute_name: :account_id
      def execute
        logger = ::Arke::Log
        logger.level = Logger::DEBUG
        acc_config = accounts_configs.find {|a| a["id"] == account_id }
        raise "account #{account_id} not found" unless acc_config

        EM.synchrony do
          ex = Arke::Exchange.create(acc_config)
          orders = ex.fetch_openorders(market)
          liquidity = {}
          orders.each do |order|
            pp order
            market = ex.market_config(order.market)

            case order.side
            when :buy
              c = market["quote_unit"]
              liquidity[c] ||= 0.to_d
              liquidity[c] += order.price * order.amount
            when :sell
              c = market["base_unit"]
              liquidity[c] ||= 0.to_d
              liquidity[c] += order.amount
            else
              logger.error "Unexpected order side #{order.side}"
            end
          end
          puts "#{orders.size} orders"
          puts 'Liquidity used:'
          liquidity.each do |c, amount|
            puts "#{c}: %f" % [amount]
          end
          EM.stop
        end
      end
    end

    subcommand "list", "List open orders", List
    subcommand "create", "Create an order", Create
    subcommand "cancel", "Cancel an order", Cancel
    subcommand "cancel-all", "Cancel all orders", CancelAll
  end
end
