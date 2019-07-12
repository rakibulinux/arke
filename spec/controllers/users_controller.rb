require 'rails_helper'

RSpec.describe UsersController, type: :controller do
  let(:user_uid){ SecureRandom.hex(6) }
  let(:user_params) { { uid: user_uid, level: 3, role: 'admin', state: 'active', email: 'test@test.com' } }
  let(:auth_header) { { 'Authorization' => "Bearer #{jwt_for(user_params)}" }}

  describe 'GET /users/me' do
    it 'returns unathorized' do
      get :me, params: { }

      expect(response.code).to eq '401'
      expect(response.body).to eq 'Unauthorized'
    end

    it 'returns current user' do
      request.headers.merge! auth_header
      get :me, params: {}

      result = JSON.parse(response.body)
      expect(response).to be_successful
      expect(result["email"]).to eq 'test@test.com'
      expect(result["uid"]).to eq user_uid
      expect(result["level"]).to eq 3
      expect(result["role"]).to eq 'admin'
      expect(result["state"]).to eq 'active'
    end

    context 'when user already exists in db' do
      let!(:user) { create(:user, user_params) }

      it 'return current user' do
        # Check total number of users before request
        expect(User.count).to eq 1

        request.headers.merge! auth_header
        get :me, params: {}

        result = JSON.parse(response.body)
        expect(response).to be_successful
        expect(result["email"]).to eq 'test@test.com'
        expect(result["uid"]).to eq user_uid
        expect(result["level"]).to eq 3
        expect(result["role"]).to eq 'admin'
        expect(result["state"]).to eq 'active'
        expect(User.count).to eq 1
      end
    end
  end
end
