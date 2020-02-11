module Arke
  module Command
    class Show < Clamp::Command

      class Base < Clamp::Command
        include Arke::Helpers::Commands
        option "--config", "FILE_PATH", "Strategies config file", default: "config/strategies.yml"
        option "--dry", :flag, "dry run on the target"
        option "--backtrace", :flag, "display errors backtrace", default: false

        def execute
          accounts_configs.each do |acc_config|
            begin
              platform_do(Arke::Exchange.create(acc_config))
            rescue StandardError => e
              if backtrace?
                ::Arke::Log.error("#{e}:#{e.backtrace.join("\n")}")
              else
                ::Arke::Log.error("#{e}")
              end
            end
          end
        end
      end

      class DepositAddresses < Base
        option "--currency", "CURRENCY_CODE", "Display only the address for this currency", default: nil

        def platform_do(account)
          puts "#{account.id}: #{account.host}".blue
          return puts "  get balances not supported".red unless account.respond_to?(:get_deposit_address)
          return puts "  get balances not supported".red unless account.respond_to?(:get_balances)
          return puts "  secret not configured".orange unless account.secret

          currencies = currency ? [{"type" => "coin", "id" => currency}] : account.currencies
          currencies.each do |c|
            d = c["type"] == "coin" ? account.get_deposit_address(c["id"])["address"] : "FIAT"
            puts(("  %-8s: %s" % [c["id"], d]).green)
          end
        end
      end

      class Balances < Base
        option "--zero", :flag, "Display currencies with zero balance", default: false

        def platform_do(account)
          puts "#{account.id}: #{account.host}".blue
          return puts "  get balances not supported".red unless account.respond_to?(:get_balances)
          return puts "  secret not configured".yellow unless account.secret

          account.get_balances.each do |b|
            if b["total"] && (zero? || b["total"].to_f.positive?)
              puts ("  %-8s: %0.4f (free: %0.4f locked: %0.4f)" % [b["currency"], b["total"], b["free"], b["locked"]]).green
            end
          end
        end
      end

      class MarketConfig < Base
        parameter "ACCOUNT_ID", "market id on the target platform", attribute_name: :account_id
        parameter "MARKET_ID", "market id on the target platform", attribute_name: :market_id
        def execute
          logger = ::Arke::Log
          logger.level = Logger::DEBUG
          acc_config = accounts_configs.find {|a| a["id"].to_s == account_id.to_s }
          raise "account not found for #{account_id}" unless acc_config

          ex = Arke::Exchange.create(acc_config)
          config = ex.market_config(market_id)

          puts "%18s  %s" % ["id", config["id"].to_s]
          puts "%18s  %s" % ["base_unit", config["base_unit"].to_s]
          puts "%18s  %s" % ["quote_unit", config["quote_unit"].to_s]
          puts "%18s  %s" % ["min_price", config["min_price"]&.to_f]
          puts "%18s  %s" % ["max_price", config["max_price"]&.to_f]
          puts "%18s  %s" % ["min_amount", config["min_amount"]&.to_f]
          puts "%18s  %s" % ["amount_precision", config["amount_precision"]&.to_f]
          puts "%18s  %s" % ["price_precision", config["price_precision"]&.to_f]
        end
      end

      subcommand "balances", "Show platforms balances", Balances
      subcommand "deposit_addresses", "Show platforms deposits addresses", DepositAddresses
      subcommand "market_config", "Show a market configuration", MarketConfig
    end
  end
end
