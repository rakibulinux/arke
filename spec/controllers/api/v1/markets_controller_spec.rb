require 'rails_helper'

RSpec.describe Api::V1::MarketsController, type: :controller do

  let(:auth_header) { { 'Authorization' => "Bearer #{jwt_for({email: 'email@test.com', uid: 'ID234234', level: 3, role: 'admin', state: 'active'})}" }}

  describe 'GET #index' do
    let!(:market1) { create(:market, :btcusd) }
    let!(:market2) { create(:market, :btcusd) }
    let!(:market3) { create(:market, :ethusd, exchange_id: market1.exchange_id) }

    it 'returns exchanges markets' do
      request.headers.merge! auth_header
      get :index, params: { market: { exchange_id: market1.exchange_id } }

      result = JSON.parse(response.body)
      expect(response).to be_successful
      expect(result.count).to eq 2
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
