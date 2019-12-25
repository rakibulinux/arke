# encoding: UTF-8
# frozen_string_literal: true

module Api::V2::Private
  class AccountsController < BaseController
    before_action :set_account, only: [:update, :destroy, :show]

    # GET /accounts
    def index
      accounts = @user.accounts.where(params.permit(:id))
      accounts = accounts.order(params[:order_by] => params[:order] || 'ASC') if params[:order_by]

      paginate json: accounts
    end

    # GET /accounts/1
    def show
      json_response(@account, 200)
    end

    # POST /accounts
    def create
      @account = Account.new(account_params.merge(user: @user))

      if @account.save
        json_response(@account, 201)
      else
        json_response({ errors: ['accounts.create_failed'] }, 422)
      end
    end

    # PATCH/PUT /accounts/1
    def update
      if @account.update(account_params)
        json_response(@account, 200)
      else
        json_response({ errors: ['accounts.update_failed'] }, 422)
      end
    end

    # DELETE /accounts/1
    def destroy
      @account.destroy
    end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_account
      @account = @user.accounts.find_by(id: params[:id])
      json_response({ errors: ['accounts.doesnt_exist'] }, 404) if @account.nil?
    end

    # Only allow a trusted parameter "white list" through.
    def account_params
      params.require(:account).permit(:exchange_id, :name, api_key: [:key, :secret])
    end
  end
end
