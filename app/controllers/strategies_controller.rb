class StrategiesController < ApplicationController
  before_action :set_strategy, only: [:show, :update, :destroy]

  # GET /strategies
  def index
    @strategies = Strategy.all

    render json: @strategies
  end

  # GET /strategies/1
  def show
    render json: @strategy
  end

  # POST /strategies
  def create
    @strategy = Strategy.new(strategy_params)

    if @strategy.save
      render json: @strategy, status: :created, location: @strategy
    else
      render json: @strategy.errors, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /strategies/1
  def update
    if @strategy.update(strategy_params)
      render json: @strategy
    else
      render json: @strategy.errors, status: :unprocessable_entity
    end
  end

  # DELETE /strategies/1
  def destroy
    @strategy.destroy
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_strategy
      @strategy = Strategy.find(params[:id])
    end

    # Only allow a trusted parameter "white list" through.
    def strategy_params
      params.require(:strategy).permit(:user_id, :source_id, :target_id, :name, :driver, :frequency, :params, :state, :debug)
    end
end
