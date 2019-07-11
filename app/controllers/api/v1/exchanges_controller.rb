class Api::V1::ExchangesController < ApplicationController

  # GET /exchanges
  def index
    json_response(Exchange.all, 200)
  end
end
