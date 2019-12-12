# encoding: UTF-8
# frozen_string_literal: true

module Api::V2::Admin
  class RobotsController < ApplicationController
    before_action :set_robot, only: [:show, :update, :destroy]

    # GET /robots
    def index
      robots = Robot.all

      response.headers['X-Total-Count'] = robots.count

      json_response(robots, 200)
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
      @robot.destroy
    end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_robot
      @robot = Robot.find_by(id: params[:id])
      json_response({ errors: ['robots.doesnt_exist'] }, 404) if @robot.nil?
    end

    # Only allow a trusted parameter "white list" through.
    def robot_params
      params.require(:robot).permit(:source_market_id, :source_id, :target_market_id,
                                       :target_id, :name, :driver, :interval, :params, :state, :strategy, :user_id)
    end
  end
end
