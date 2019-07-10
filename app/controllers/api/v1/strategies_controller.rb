class Api::V1::StrategiesController < ApplicationController
  before_action :set_strategy, only: [:show, :update, :destroy]

  # GET /strategies
  def index
    json_response(@user.strategies, 200)
  end

  # GET /strategies/1
  def show
    json_response(@strategy, 200)
  end

  # POST /strategies
  def create
    @strategy = Strategy.new(strategy_params.merge(user_id: @user.id))

    if @strategy.save
      json_response(@strategy, 201)
    else
      json_response({ errors: ['strategies.create_failed'] }, 422)
    end
  end

  # PATCH/PUT /strategies/1
  def update
    if @strategy.update(strategy_params)
      json_response(@strategy, 200)
    else
      json_response({ errors: ['strategies.update_failed'] }, 422)
    end
  end

  # DELETE /strategies/1
  def destroy
    @strategy.destroy
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_strategy
      @strategy = @user.strategies.find_by(id: params[:id])
      json_response({ errors: ['strategies.doesnt_exist'] }, 404) if @strategy.nil?
    end

    # Only allow a trusted parameter "white list" through.
    def strategy_params
      params.require(:strategy).permit(:source_market_id, :source_id, :target_market_id,
                                       :target_id, :name, :driver, :interval, :params, :state)
    end
end
