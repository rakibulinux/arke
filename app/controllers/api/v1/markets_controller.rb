class Api::V1::MarketsController < ApplicationController

  # GET /markets
  def index
    markets = Market.where(market_params.reject { |_k, v| v.nil? })

    json_response(markets, 200)
  end

  private
  # Only allow a trusted parameter "white list" through.
  def market_params
    params.require(:market).permit(:exchange_id)
  end
end
