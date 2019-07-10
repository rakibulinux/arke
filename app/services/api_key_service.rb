class ApiKeyService

  class << self
    PREFIX = 'secret/apikeys'

    def create(account, api_key)
      return nil if exists?(account)
      vault.write(api_key_path(account), api_key)
    end

    def update(account, api_key)
      return nil unless exists?(account)
      vault.write(api_key_path(account), api_key)
    end

    def read(account)
      secret = vault.read(api_key_path(account))
      secret.nil? ? nil : secret.data
    end

    def delete(account)
      vault.delete(api_key_path(account)) # Vault.logical.delete always returns true
    end

    def exists?(account)
      vault.read(api_key_path(account)).present?
    end

    def prune!
      raise 'Trying to prune apikeys in production mode.' if Rails.env.production?
      vault.list(PREFIX).map { |path| vault.delete("#{PREFIX}/#{path}") }
    end

    private

    def vault
      Vault.logical
    end

    # Key used for vault should not change on model update, that's why user_id/name/exchange_id is not used here.
    # Using account_id means that api_key should be created after account gets id.
    def api_key_path(account)
      "#{PREFIX}/#{account.id}"
    end
  end
end
