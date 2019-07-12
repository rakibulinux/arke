class UsersController < ApplicationController

  # GET /users/me
  def me
    render json: @user
  end
end
