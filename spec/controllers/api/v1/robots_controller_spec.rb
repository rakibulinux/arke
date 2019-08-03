require 'rails_helper'

RSpec.describe Api::V1::RobotsController, type: :controller do
  let(:user_params) { { email: 'email@test.com', uid: 'ID234234', level: 3, role: 'admin', state: 'active' } }
  let!(:user1) { create(:user, user_params) }
  let!(:user2) { create(:user) }
  let!(:strategy1) { create(:strategy, name: 'microtrades', user_id: user1.id) }
  let!(:strategy2) { create(:strategy, name: 'microtrades1', user_id: user1.id) }
  let!(:strategy3) { create(:strategy, name: 'microtrades2', user_id: user1.id) }
  let!(:strategy4) { create(:strategy, name: 'microtrades3', user_id: user1.id) }
  let!(:strategy5) { create(:strategy, name: 'microtrades4', user_id: user1.id) }
  let!(:strategy6) { create(:strategy, name: 'microtrades4', user_id: user2.id) }

  let(:auth_header) { { 'Authorization' => "Bearer #{jwt_for(user_params)}" }}

  before(:all) { WebMock.disable! }
  after(:all) { WebMock.enable! }

  describe 'GET #index' do
    it 'returns user robots' do
      request.headers.merge! auth_header
      get :index, params: {}
      result = JSON.parse(response.body)
      expect(response).to be_successful
      expect(result.count).to eq 5
      expect(result.map { |strategy| strategy['user_id'] } ).to all eq user1.id
    end

    context 'unauthorized' do
      it 'returns unauthorized' do
        get :index, params: { id: 1 }

        expect(response.code).to eq '401'
        expect(response.body).to eq 'Unauthorized'
      end
    end
  end

  describe 'GET #show' do
    context 'authorized' do
      before { request.headers.merge! auth_header }

      it 'returns user strategy' do
        get :show, params: { id: strategy1.id }

        result = JSON.parse(response.body)
        expect(response).to be_successful
        expect(result.except('created_at', 'updated_at')).to eq strategy1.attributes.except('created_at', 'updated_at')
      end

      it 'returns error when strategy doesnt exist for current user' do
        get :show, params: { id: strategy6.id }

        result = JSON.parse(response.body)
        expect(response.code).to eq '404'
        expect(result['errors']).to eq(['robots.doesnt_exist'])
      end

      it 'returns error when strategy doesnt exist' do
        get :show, params: { id: 10 }

        result = JSON.parse(response.body)
        expect(response.code).to eq '404'
        expect(result['errors']).to eq(['robots.doesnt_exist'])
      end
    end

    context 'unauthorized' do
      it 'returns unauthorized' do
        get :show, params: { id: 1 }

        expect(response.code).to eq '401'
        expect(response.body).to eq 'Unauthorized'
      end
    end
  end

  describe 'POST #create' do
    let!(:strategy) { create(:strategy, name: 'microtrades6') }
    let(:valid_attributes) { strategy.slice(:source_id, :target_id, :source_market_id, :target_market_id, :name, :driver, :interval) }

    context 'authorized' do
      before { request.headers.merge! auth_header }

      context 'with valid params' do
        it 'creates a new  user strategy' do
          expect {
            post :create, params: { strategy: valid_attributes }
          }.to change { user1.robots.count }.by(1)
        end

        it 'renders a JSON response with the new user strategy' do
          post :create, params: { strategy: valid_attributes }

          result = JSON.parse(response.body)
          expect(response).to be_successful
          expect(response.code).to eq '201'
          expect(result['name']).to eq 'microtrades6'
          expect(result['user_id']).to eq user1.id
        end
      end

      context 'with invalid params' do
        it 'renders a JSON response with errors for the new user strategy' do
          post :create, params: { strategy: { target_market_id: 'btcusd'} }

          result = JSON.parse(response.body)
          expect(response.code).to eq '422'
          expect(result['errors']).to eq(['robots.create_failed'])
        end
      end
    end

    context 'unauthorized' do
      it 'returns unauthorized' do
        post :create, params: { strategy: valid_attributes}

        expect(response.code).to eq '401'
        expect(response.body).to eq 'Unauthorized'
      end
    end
  end

  describe 'PUT #update' do
    context 'authorized' do
      before { request.headers.merge! auth_header }

      context 'with valid params' do
        it 'updates the requested user strategy' do
          put :update, params: { id: strategy2.id, strategy: { name: 'microtrades3' } }

          result = JSON.parse(response.body)
          expect(result['name']).to eq 'microtrades3'
        end
      end

      context 'with invalid params' do
        let(:invalid_attributes) { { target_market_id: 'btcusd' } }

        it 'renders a JSON response with errors for the user strategy' do
          put :update, params: { id: strategy2.id, strategy: invalid_attributes }

          result = JSON.parse(response.body)
          expect(response.code).to eq '422'
          expect(result['errors']).to eq(['robots.update_failed'])
        end

        it 'returns error when user strategy doesnt exist' do
          put :update, params: { id: 10, strategy: invalid_attributes }

          result = JSON.parse(response.body)
          expect(response.code).to eq '404'
          expect(result['errors']).to eq(['robots.doesnt_exist'])
        end
      end
    end

    context 'unauthorized' do
      it 'returns unauthorized' do
        put :update, params: { id: strategy2.id, strategy: { name: 'microtrades3' } }

        expect(response.code).to eq '401'
        expect(response.body).to eq 'Unauthorized'
      end
    end
  end

  describe 'DELETE #destroy' do
    context 'authorized' do
      before { request.headers.merge! auth_header }

      it 'destroys the requested strategy' do
        expect {
          delete :destroy, params: { id: strategy4.id }
        }.to change(Robot, :count).by(-1)
      end

      it 'returns error when strategy doesnt exist' do
        delete :destroy, params: { id: 10 }

        result = JSON.parse(response.body)
        expect(response.code).to eq '404'
        expect(result['errors']).to eq(['robots.doesnt_exist'])
      end
    end

    context 'unauthorized' do
      it 'returns unauthorized' do
        delete :destroy, params: { id: 4 }

        expect(response.code).to eq '401'
        expect(response.body).to eq 'Unauthorized'
      end
    end
  end
end
