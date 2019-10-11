module Arke
  module Command
    class Show < Clamp::Command

      class Base < Clamp::Command
        include Arke::Helpers::Commands
        option "--config", "FILE_PATH", "Strategies config file", default: "config/strategies.yml"
        option "--dry", :flag, "dry run on the target"

        def execute
          accounts_configs.each do |acc_config|
            platform_do(Arke::Exchange.create(acc_config))
          end
        end
      end

      class DepositAddresses < Base
        def platform_do(account)
          puts "#{account.id}: #{account.host}".blue
          return puts "  get balances not supported".red unless account.respond_to?(:get_deposit_address)
          return puts "  get balances not supported".red unless account.respond_to?(:get_balances)
          return puts "  secret not configured".orange unless account.secret

          account.currencies.each do |c|
            d = c["type"] == "coin" ? account.get_deposit_address(c["id"])["address"] : "FIAT"
            puts ("  %-8s: %s" % [c["id"], d]).green
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

      subcommand "balances", "Show platforms balances", Balances
      subcommand "deposit_addresses", "Show platforms deposits addresses", DepositAddresses
    end
  end
end
