# frozen_string_literal: true

module Arke
  class Vault
    TOKEN     = ENV["VAULT_TOKEN"].to_s
    ADDRESS   = ENV["VAULT_ADDR"].to_s
    APP_NAME  = ENV["VAULT_APP_NAME"].to_s

    class << self
      @@initialized = false

      def initialize
        return if @@initialized

        Arke::Log.info "Initializing vault"

        raise "VAULT_TOKEN is missing in environment" if TOKEN.empty?
        raise "VAULT_ADDR is missing in environment" if ADDRESS.empty?
        raise "VAULT_APP_NAME is missing in environment" if APP_NAME.empty?

        ::Vault.token = TOKEN
        ::Vault.address = ADDRESS

        if ::Vault.logical.read("transit/keys/#{vault_key}").nil?
          Arke::Log.info "Generating the vault transit key: #{vault_key}"
          ::Vault.logical.write("transit/keys/#{vault_key}")
        end

        @@initialized = true
      end

      def vault_key
        "arke_#{APP_NAME}_secrets"
      end

      def encrypt(value)
        initialize
        encrypted = ::Vault.logical.write("transit/encrypt/#{vault_key}", plaintext: Base64.encode64(value))
        encrypted.data[:ciphertext]
      end

      def decrypt(value)
        initialize
        decrypted = ::Vault.logical.write("transit/decrypt/#{vault_key}", ciphertext: value)
        Base64.decode64(decrypted.data[:plaintext])
      end

      def auto_renew_token
        initialize
        renew_process = lambda do
          token = ::Vault.auth_token.lookup(TOKEN)
          time = token.data[:ttl] * (1 + rand) * 0.1
          Arke::Log.debug "[VAULT] Token will renew in %.0f sec" % time
          sleep(time)
          ::Vault.auth_token.renew(token.data[:id])
          Arke::Log.info "[VAULT] Token renewed"
        end

        token = ::Vault.auth_token.lookup(TOKEN)

        if token.data[:renewable]
          Arke::Log.info "[VAULT] Starting token renew thread"
          Thread.new do
            loop do
              renew_process.call
            rescue StandardError => e
              Arke::Log.error { e.to_s }
              sleep 60
            end
          end
        else
          Arke::Log.info "[VAULT] Token is not renewable"
        end
      end
    end
  end
end
