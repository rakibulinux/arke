class Api::V1::TickersController < Api::V1::BaseController

  # GET /tickers
  def index
    market = Market.find_by(exchange_id: ticker_params[:exchange_id])

    return json_response({ errors: ['markets.doesnt_exist'] }, 404) if market.nil?

    json_response(market.ticker, 200)
  end

  private
  # Only allow a trusted parameter "white list" through.
  def ticker_params
    params.require(:ticker).permit(:exchange_id)
  end
end
