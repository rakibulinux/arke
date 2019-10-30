class Api::V1::UsersController < Api::V1::BaseController

  # GET /users/me
  def me
    json_response(@user, 200)
  end
end
