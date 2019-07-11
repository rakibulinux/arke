require 'rails_helper'

RSpec.describe Api::V1::ExchangesController, type: :controller do
  let(:auth_header) { { 'Authorization' => "Bearer #{jwt_for({email: 'email@test.com', uid: 'ID234234', level: 3, role: 'admin', state: 'active'})}" }}

  before do
    create(:exchange)
    create(:exchange)
    create(:exchange)
    create(:exchange)
    create(:exchange)
  end

  describe 'GET #index' do
    it 'returns exchanges' do
      request.headers.merge! auth_header
      get :index, params: {}

      result = JSON.parse(response.body)
      expect(response).to be_successful
      expect(result.count).to eq Exchange.count
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
