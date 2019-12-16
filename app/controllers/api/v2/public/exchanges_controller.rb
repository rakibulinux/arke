module Api::V2::Public
  class ExchangesController < BaseController

    # GET /exchanges
    def index
      exchanges = Exchange.where(params.permit(:id))
      exchanges = exchanges.order(params[:order_by] => params[:order] || 'ASC') if params[:order_by]
      paginate json: exchanges
    end
  end
end
