# encoding: UTF-8
# frozen_string_literal: true

require_dependency 'arke/middleware/jwt_authenticator'

class ApplicationController < ActionController::API
  include Response
  include Errors
end
