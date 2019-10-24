class Account < ApplicationRecord
  include Vault::EncryptedModel

  vault_lazy_decrypt!

  belongs_to :user, required: true
  belongs_to :exchange, required: true

  has_many :balances
  has_many :trades
  has_and_belongs_to_many :robots

  validates :name, presence: true, length: { minimum: 3 }, format: { with: /\A[a-z]+[a-z0-9_-]*\z/}
  
  vault_attribute :api_key
  vault_attribute :api_secret

  def as_json(options={})
    super(except: %i[api_key_encrypted api_secret_encrypted])
  end
end
