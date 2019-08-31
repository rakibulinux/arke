module Arke
  module Command
    class Show < Clamp::Command

      class Base < Clamp::Command
        include Arke::Helpers::Commands
        option "--config", "FILE_PATH", "Strategies config file", default: "config/strategies.yml"
        option "--dry", :flag, "dry run on the target"

        def execute
          each_platform do |ex_config, acc_config|
            platform_do(ex_config, acc_config)
          end
        end
      end

      class DepositAddresses < Base
        def platform_do(ex_config, acc_config)
          ex = Arke::Exchange.create(acc_config)
          ex.configure_market(ex_config["market"])
          puts "#{ex.driver}".blue
          unless ex.respond_to?(:get_deposit_address)
            return puts "  get balances not supported".red
          end
            unless ex.respond_to?(:get_balances)
            return puts "  get balances not supported".red
          end
          unless acc_config["secret"]
            return puts "  secret not configured".orange
          end
          ex.currencies.each do |c|
            d = c["type"] == "coin" ? ex.get_deposit_address(c["id"])["address"] : "FIAT"
            puts ("  %-8s: %s" % [c["id"], d]).green
          end
        end
      end

      class Balances < Base
        option "--zero", :flag, "Display currencies with zero balance", :default => false

        def platform_do(ex_config, acc_config)
          ex = Arke::Exchange.create(acc_config)
          ex.configure_market(ex_config["market"])
          puts "#{ex.driver}".blue
          unless ex.respond_to?(:get_balances)
            return puts "  get balances not supported".red
          end
          unless acc_config["secret"]
            return puts "  secret not configured".yellow
          end
          ex.get_balances.each do |b|
            if b["total"] && (zero? || b["total"].to_f > 0)
              puts ("  %-8s: %0.4f (free: %0.4f locked: %0.4f)" % [b["currency"], b["total"], b["free"], b["locked"]]).green
            end
          end
        end
      end

      class OpenOrders < Base
        def platform_do(ex_config, acc_config)
          ex = Arke::Exchange.create(acc_config)
          ex.configure_market(ex_config["market"])
          puts "#{ex.driver}".blue
          ex.fetch_openorders
          puts ex.open_orders
        end
      end

      subcommand "balances", "Show platforms balances", Balances
      subcommand "openorders", "Show platforms openorders", OpenOrders
      subcommand "deposit_addresses", "Show platforms deposits addresses", DepositAddresses
    end
  end
end
