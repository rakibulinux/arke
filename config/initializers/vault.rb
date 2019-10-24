require 'vault/rails'

Vault.configure do |config|
  config.address = ENV.fetch('VAULT_ADDR', 'http://localhost:8200')
  config.token = ENV.fetch('VAULT_TOKEN', 'changeme')
  config.ssl_verify = false
  config.timeout = 60
  config.application = ENV.fetch('VAULT_APP_NAME', 'arke')
end
