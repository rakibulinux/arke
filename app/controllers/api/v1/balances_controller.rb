class Api::V1::BalancesController < ApplicationController

  # GET /balances
  def index
    balances = @user.accounts.collect { |account| account.balances }
    json_response(balances.flatten, 200)
  end
end
