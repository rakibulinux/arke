# frozen_string_literal: true

module Arke::Command
  class Secrets < Clamp::Command
    class New < Clamp::Command
      include Arke::Helpers::Commands
      option "--backtrace", :flag, "display errors backtrace", default: false

      parameter "secret", "The secret to encrypt with vault", attribute_name: :secret

      def execute
        logger = ::Arke::Log
        puts Arke::Vault::encrypt(secret)
      rescue StandardError => e
        if backtrace?
          logger.error("#{e}:#{e.backtrace.join("\n")}")
        else
          logger.error(e.to_s)
        end
      end
    end
    subcommand "new", "Create a new encrypted secret", New
  end
end
