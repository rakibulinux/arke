class Account < ApplicationRecord
  belongs_to :user
  belongs_to :exchange

  def key
    'key_from_vault'
  end

  def secret
    'secret_from_vault'
  end

  def to_h
    {
      "driver" => exchange.name,
      "host" => exchange.rest,
      "ws" => exchange.ws,
      "key" => key,
      "secret" => secret,
      "delay" => (1.0 / exchange.rate)
    }
  end
end
