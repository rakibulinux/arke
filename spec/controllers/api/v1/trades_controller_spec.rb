require 'rails_helper'

RSpec.describe Api::V1::TradesController, type: :controller do
  let(:user_params) { { email: 'email@test.com', uid: 'ID234234', level: 3, role: 'admin', state: 'active' } }
  let!(:user1) { create(:user, user_params) }
  let!(:account1) { create(:account, user_id: user1.id) }
  let!(:trade1) { create(:trade, account_id: account1.id) }
  let!(:trade2) { create(:trade, account_id: account1.id) }
  let!(:trade3) { create(:trade, account_id: account1.id) }
  let(:auth_header) { { 'Authorization' => "Bearer #{jwt_for(user_params)}" }}

  describe 'GET #index' do
    it 'returns user balances' do
      request.headers.merge! auth_header
      get :index, params: {}

      result = JSON.parse(response.body)
      expect(response).to be_successful
      expect(result.count).to eq 3
      expect(result.map { |trade| trade['account_id'] } ).to all eq account1.id
    end

    context 'unauthorized' do
      it 'returns unauthorized' do
        get :index, params: { id: 1 }

        expect(response.code).to eq '401'
        expect(response.body).to eq 'Unauthorized'
      end
    end
  end
end
