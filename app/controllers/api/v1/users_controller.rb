class Api::V1::UsersController < ApplicationController

  # GET /users/me
  def me
    json_response(@user, 200)
  end
end
