# encoding: UTF-8
# frozen_string_literal: true

module Api::V2::Admin
  class UsersController < ApplicationController
    before_action :set_user, only: [:show, :update, :destroy]

    def index
      users = User.where(params.permit(:id, :level, :role, :email, :uid))
      users = users.order(params[:order_by] => params[:order] || 'ASC') if params[:order_by]

      paginate json: users
    end

    # GET /users/1
    def show
      json_response(@user, 200)
    end

  private

    def set_user
      @user = User.find_by(params.permit(:id))
      json_response({ errors: ['users.doesnt_exist'] }, 404) if @user.nil?
    end
  end
end
