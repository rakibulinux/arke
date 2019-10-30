class Api::V1::TradesController < Api::V1::BaseController

  # GET /trades
  def index
    trades = @user.accounts.collect { |account| account.trades }
    json_response(trades.flatten, 200)
  end
end
