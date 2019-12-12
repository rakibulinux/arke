# encoding: UTF-8
# frozen_string_literal: true

module Api::V2::Admin
  class UsersController < ApplicationController

    def index
      users = User.all

      users = User.where(params.permit('id')) if params[:id]

      response.headers['X-Total-Count'] = users.count
      json_response(users, 200)
    end
  end
end
