# encoding: UTF-8
# frozen_string_literal: true

require 'openssl'
require 'base64'

module APITestHelpers
  #
  # Generates valid JWT for member, allows to pass additional payload.
  #
  def jwt_for(member, payload = { x: 'x', y: 'y', z: 'z' })
    jwt_build(payload.merge(member))
  end

  #
  # Generates valid JWT. Accepts payload as argument. Add fields required for JWT to be valid.
  #
  def jwt_build(payload)
    jwt_encode payload.reverse_merge \
      iat: Time.now.to_i,
      exp: 20.minutes.from_now.to_i,
      jti: SecureRandom.uuid,
      sub: 'session',
      iss: 'peatio',
      aud: ['peatio']
  end

  #
  # Generates JWT token based on payload. Doesn't add any extra fields to payload.
  #
  def jwt_encode(payload)
    OpenSSL::PKey.read(Base64.urlsafe_decode64(jwt_keypair_encoded[:private])).yield_self do |key|
      JWT.encode(payload, key, 'RS256')
    end
  end

  def jwt_keypair_encoded
    OpenSSL::PKey::RSA.generate(2048).yield_self do |p|
      Rails.configuration.x.keystore.public_key = p.public_key
      Rails.configuration.x.keystore.pair_key = p
      Rails.configuration.x.jwt_public_key = p.public_key
      { public:  Base64.urlsafe_encode64(p.public_key.to_pem),
        private: Base64.urlsafe_encode64(p.to_pem) }
    end
  end
end

RSpec.configure { |config| config.include APITestHelpers }
