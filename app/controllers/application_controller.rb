# encoding: UTF-8
# frozen_string_literal: true

require_dependency 'arke/middleware/jwt_authenticator'

class ApplicationController < ActionController::API
  include Response

  before_action :auth_user!
  before_action :create_user

  private

  def current_user
    return @current_user if @current_user

    if request.headers['Authorization']
      auth = Arke::Middleware::JWTAuthenticator.new(pubkey: Rails.configuration.x.keystore.public_key)
      @current_user = auth.before(request.headers)
    end
  end

  def create_user
    unathorized unless @current_user

    @user = User.find_by(uid: @current_user[:uid])

    if @user.nil?
      @user = User.create(current_user.slice(:uid, :email, :level, :role, :state))

      render json: @user.errors, status: :unprocessable_entity unless @user
    end
  end

  def auth_user!
    unathorized unless current_user
  end

  def unathorized
    render json: 'Unauthorized', status: :unauthorized
  end
end
