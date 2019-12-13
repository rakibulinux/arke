# encoding: UTF-8
# frozen_string_literal: true

module Api::V2::Admin
  class RobotsController < ApplicationController
    before_action :set_robot, only: [:show, :update, :destroy]

    # GET /robots
    def index
      robots = Robot.where(params.permit(:id, :user_id, :strategy, :state))
      robots = robots.order(params[:order_by] => params[:order] || 'ASC') if params[:order_by]

      paginate json: robots
    end

    # GET /robots/1
    def show
      json_response(@robot, 200)
    end

    # POST /robots
    def create
      @robot = Robot.new(robot_params)

      if @robot.save
        json_response(@robot, 201)
      else
        json_response({ errors: ['robots.create_failed'] }, 422)
      end
    end

    # PATCH/PUT /robots/1
    def update
      if @robot.update(robot_params)
        json_response(@robot, 200)
      else
        json_response({ errors: ['robots.update_failed'] }, 422)
      end
    end

    # DELETE /robots/1
    def destroy
      json_response(@robot.destroy, 200)
    end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_robot
      @robot = Robot.find_by(params.permit(:id))
      json_response({ errors: ['robots.doesnt_exist'] }, 404) if @robot.nil?
    end

    # Only allow a trusted parameter "white list" through.
    def robot_params
      params.require(:robot).permit(:name, :state, :strategy, :user_id, params: [
                                                                                  :spread_bids,
                                                                                  :spread_asks,
                                                                                  :limit_asks_base,
                                                                                  :limit_bids_base,
                                                                                  :max_amount_per_order,
                                                                                  :levels_size,
                                                                                  :levels_count,
                                                                                  :side,
                                                                                  :linked_strategy_id,
                                                                                  :min_amount,
                                                                                  :max_amount,
                                                                                ])
    end
  end
end


