require 'rails_helper'

RSpec.describe Api::V1::TickersController, type: :controller do

  let(:auth_header) { { 'Authorization' => "Bearer #{jwt_for({email: 'email@test.com', uid: 'ID234234', level: 3, role: 'admin', state: 'active'})}" }}

  describe 'GET #index' do
    context 'authorized' do
      before { request.headers.merge! auth_header }

      let!(:ticker1) { create(:ticker) }
      let!(:ticker2) { create(:ticker) }
      let!(:ticker3) { create(:ticker) }

      it 'returns exchanges tickers' do
        get :index, params: { ticker: { exchange_id: ticker1.market.exchange_id } }

        result = JSON.parse(response.body)
        expect(response).to be_successful
        expect(result).to include ticker1.attributes
      end

      it 'returns error when market with specified exchanged_id doesnt exist ' do
        get :index, params: { ticker: { exchange_id: 0 } }

        result = JSON.parse(response.body)
        expect(response.code).to eq '404'
        expect(result['errors']).to eq(['markets.doesnt_exist'])
      end
    end

    context 'unathorized' do
      it 'returns unauthorized' do
        get :index, params: {}

        expect(response.code).to eq '401'
        expect(response.body).to eq 'Unauthorized'
      end
    end
  end
end
