class Api::V1::ExchangesController < Api::V1::BaseController

  # GET /exchanges
  def index
    json_response(Exchange.all, 200)
  end
end
