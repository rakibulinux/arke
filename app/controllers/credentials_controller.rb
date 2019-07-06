class CredentialsController < ApplicationController
  before_action :set_credential, only: [:show, :update, :destroy]

  # GET /credentials
  def index
    @credentials = Credential.all

    render json: @credentials
  end

  # GET /credentials/1
  def show
    render json: @credential
  end

  # POST /credentials
  def create
    @credential = Credential.new(credential_params)

    if @credential.save
      render json: @credential, status: :created, location: @credential
    else
      render json: @credential.errors, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /credentials/1
  def update
    if @credential.update(credential_params)
      render json: @credential
    else
      render json: @credential.errors, status: :unprocessable_entity
    end
  end

  # DELETE /credentials/1
  def destroy
    @credential.destroy
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_credential
      @credential = Credential.find(params[:id])
    end

    # Only allow a trusted parameter "white list" through.
    def credential_params
      params.require(:credential).permit(:user_id, :exchange_id, :name)
    end
end
