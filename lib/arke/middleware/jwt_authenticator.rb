# encoding: UTF-8
# frozen_string_literal: true

module Arke::Middleware
  class JWTAuthenticator

    def initialize(options)
      @pubkey = options[:pubkey]
      raise 'Public key missing' if @pubkey.nil?
    end

    def before(headers)
      token = headers['Authorization']
      raise 'Header Authorization missing' if token.nil?
      authenticator.authenticate!(token)
    end

    private

    def authorization_present?(headers)
      headers.key?('Authorization')
    end

    def authenticator
      @authenticator ||=
        Peatio::Auth::JWTAuthenticator.new(@pubkey)
    end
  end
end
