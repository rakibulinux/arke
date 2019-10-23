class Account < ApplicationRecord
  belongs_to :user, required: true
  belongs_to :exchange, required: true

  has_many :balances
  has_many :trades
  has_and_belongs_to_many :robots

  validates :name, presence: true, length: { minimum: 3 }, format: { with: /\A[a-z]+[a-z0-9_-]*\z/}

  ## validates :api_key, with: :key_validator, strict: true

  ## after_create :create_api_key
  ## after_update :update_api_key
  ## after_destroy :delete_api_key

  ## def api_key
  ##   new_record? ? @key : ApiKeyService.read(self)
  ## end

  ## def api_key=(data)
  ##   @key = data
  ## end

  ## def to_h
  ##   key = api_key
  ##   {
  ##     "driver" => exchange.name,
  ##     "host" => exchange.rest,
  ##     "ws" => exchange.ws,
  ##     "delay" => (1.0 / exchange.rate),
  ##     "key" => key[:key],
  ##     "secret" => key[:secret],
  ##   }
  ## end

  ## private

  ## def create_api_key
  ##   raise ActiveRecord::Rollback.new "Could not create api key" unless ApiKeyService.create(self, @key)
  ## end

  ## def update_api_key
  ##   return unless @key
  ##   raise ActiveRecord::Rollback.new "Could not update api key" unless ApiKeyService.update(self, @key)
  ## end

  ## def delete_api_key
  ##   ApiKeyService.delete(self)
  ## end

  ## def key_validator
  ##   errors[:base] << 'invalid api key' unless valid_api_key?
  ## end

  ## def valid_api_key?
  ##   return true if @key.nil?
  ##   return false unless @key.is_a?(Hash)
  ##   return false unless @key.keys.length == 2
  ##   @key.all? { |_k, v| v.is_a?(String) && !v.empty? }
  ## end
end
