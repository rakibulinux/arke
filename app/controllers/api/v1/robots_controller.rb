class Api::V1::RobotsController < ApplicationController
  before_action :set_robot, only: [:show, :update, :destroy]

  # GET /robots
  def index
    json_response(@user.robots, 200)
  end

  # GET /robots/1
  def show
    json_response(@robot, 200)
  end

  # POST /robots
  def create
    @robot = Robot.new(robot_params.merge(user_id: @user.id))

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
      @robot = @user.robots.find_by(id: params[:id])
      json_response({ errors: ['robots.doesnt_exist'] }, 404) if @robot.nil?
    end

    # Only allow a trusted parameter "white list" through.
    def robot_params
      params.require(:robot).permit(:source_market_id, :source_id, :target_market_id,
                                       :target_id, :name, :driver, :interval, :params, :state)
    end
end
