class Api::V1::ExchangesController < ApplicationController
  before_action :set_exchange, only: [:show, :update, :destroy]

  # GET /exchanges
  def index
    @exchanges = Exchange.all

    render json: @exchanges
  end

  # GET /exchanges/1
  def show
    render json: @exchange
  end

  # POST /exchanges
  def create
    @exchange = Exchange.new(exchange_params)

    if @exchange.save
      render json: @exchange, status: :created, location: @exchange
    else
      render json: @exchange.errors, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /exchanges/1
  def update
    if @exchange.update(exchange_params)
      render json: @exchange
    else
      render json: @exchange.errors, status: :unprocessable_entity
    end
  end

  # DELETE /exchanges/1
  def destroy
    @exchange.destroy
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_exchange
      @exchange = Exchange.find(params[:id])
    end

    # Only allow a trusted parameter "white list" through.
    def exchange_params
      params.require(:exchange).permit(:name, :url, :rest, :ws, :rate)
    end
end
