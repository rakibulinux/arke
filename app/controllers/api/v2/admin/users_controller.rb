# encoding: UTF-8
# frozen_string_literal: true

module Api::V2::Admin
  class UsersController < ApplicationController

    def index
      paginate json: User.where(params.permit(:id))
    end
  end
end
