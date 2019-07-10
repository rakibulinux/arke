RSpec.describe Api::V1::AccountsController, type: :controller do
  let(:user_params) { { email: 'email@test.com', uid: 'ID234234', level: 3, role: 'admin', state: 'active' } }
  let!(:jwt_user) { create(:user, user_params) }
  let!(:other_user) { create(:user) }
  let!(:jwt_user_accounts) {
    [
      create(:account, user: jwt_user),
      create(:account, user: jwt_user),
      create(:account, user: jwt_user),
      create(:account, user: jwt_user),
      create(:account, user: jwt_user),
    ]
  }
  let!(:other_user_accounts) {
    [
      create(:account, user: other_user),
      create(:account, user: other_user),
      create(:account, user: other_user),
      create(:account, user: other_user),
      create(:account, user: other_user),
    ]
  }
  let(:auth_header) { { 'Authorization' => "Bearer #{jwt_for(user_params)}" } }

  before(:all) { WebMock.disable! }
  after(:all) { WebMock.enable! }

  describe 'GET #index' do
    it 'returns all accounts' do
      request.headers.merge! auth_header
      get :index
      result = JSON.parse(response.body)

      expect(response).to be_successful
      expect(result.length).to eq jwt_user_accounts.length
      expect(result.map { |r| r["user_id"] }).to all eq jwt_user.id
      expect(result.first.keys).to match_array %w(id user_id exchange_id name created_at updated_at)
    end

    it 'unauthorized returns 401' do
      get :index
      expect(response.body).to eq 'Unauthorized'
      expect(response.code).to eq '401'
    end
  end

  describe '# POST /accounts' do
    context 'authorized' do
      let!(:exchange) { create(:exchange) }
      let(:params) { { exchange_id: exchange.id, name: 'str1', api_key: { key: '1234', secret: 'asdsad' } } }

      before(:each) { request.headers.merge! auth_header }

      it 'creates new account' do
        expect {
          post :create, params: { account: params }
        }.to change { jwt_user.accounts.count }.by(1)

        result = JSON.parse(response.body)

        expect(response).to be_successful
        expect(result.keys).to match_array %w(id user_id exchange_id name created_at updated_at)
        expect(result).to match Account.last.attributes
      end

      it 'requires api_key' do
        expect {
          post :create, params: { account: params.except(:api_key) }
        }.not_to change { Account.count }

        result = JSON.parse(response.body)

        expect(response.status).to eq 422
        expect(result).to eq 'errors' => ['accounts.create_failed']
      end

      it 'requires name' do
        expect {
          post :create, params: { account: params.except(:name) }
        }.not_to change { Account.count }

        result = JSON.parse(response.body)

        expect(response.status).to eq 422
        expect(result).to eq 'errors' => ['accounts.create_failed']
      end

      it 'requires exchange_id' do
        expect {
          post :create, params: { account: params.except(:exchange_id) }
        }.not_to change { Account.count }

        result = JSON.parse(response.body)

        expect(response.status).to eq 422
        expect(result).to eq 'errors' => ['accounts.create_failed']
      end
    end

    it 'unauthorized returns 401' do
      post :create
      expect(response.code).to eq '401'
      expect(response.body).to eq 'Unauthorized'
    end
  end

  describe 'PUT /accounts/1' do
    let(:account) { jwt_user.accounts.sample }

    context 'authorized' do
      let(:new_api_key) { { key: 'updated_key', secret: 'updated_secret' } }
      let!(:new_exchange) { create(:exchange) }

      before(:each) { request.headers.merge! auth_header }

      it 'changes name' do
        expect {
          put :update, params: { id: account.id, account: { name: 'updated_name' } }
        }.to change { account.reload.name }.to 'updated_name'

        result = JSON.parse(response.body)

        expect(result).to match account.attributes
        expect(result.keys).to match_array %w(id user_id exchange_id name created_at updated_at)
      end

      it 'changes exchange_id' do
        expect {
          put :update, params: { id: account.id, account: { exchange_id: new_exchange.id } }
        }.to change { account.reload.exchange_id }.to new_exchange.id

        result = JSON.parse(response.body)

        expect(result).to match account.attributes
      end

      it 'udpates api_key' do
        expect {
          put :update, params: { id: account.id, account: { api_key: new_api_key } }
        }.to change { account.api_key }.to new_api_key
      end

      it 'does not update invalid api_key' do
        expect {
          put :update, params: { id: account.id, account: { api_key: { key: 'sad' } } }
        }.not_to change { account.api_key }
      end

      it 'returns error when account does not exist' do
        put :update, params: { id: Account.last.id + 1 }

        result = JSON.parse(response.body)

        expect(response.status).to eq 404
        expect(result).to eq 'errors' => ['accounts.doesnt_exist']
      end

      it 'returns error updating other user account' do
        account = other_user_accounts.sample

        expect {
          put :update, params: { id: account.id, name: 'new_name' }
        }.not_to change { account.reload.name }

        result = JSON.parse(response.body)

        expect(response.status).to eq 404
        expect(result).to eq 'errors' => ['accounts.doesnt_exist']
      end
    end

    it 'unauthorized returns 401' do
      put :update, params: { id: account.id }
      expect(response.code).to eq '401'
      expect(response.body).to eq 'Unauthorized'
    end
  end

  describe 'DELETE /accounts/1' do
    let(:account) { jwt_user.accounts.sample }

    context 'authorized' do
      before(:each) { request.headers.merge! auth_header }

      it 'deletes account' do
        expect {
          delete :destroy, params: { id: account.id }
        }.to change { jwt_user.accounts.count }.by(-1)
      end

      it 'returns error when account does not exist' do
        expect {
          delete :destroy, params: { id: Account.last.id + 1 }
        }.not_to change { Account.count }

        result = JSON.parse(response.body)

        expect(response.status).to eq 404
        expect(result).to eq 'errors' => ['accounts.doesnt_exist']
      end

      it 'returns error deleting other user account' do
        expect {
          delete :destroy, params: { id: other_user_accounts.sample.id }
        }.not_to change { Account.count }

        result = JSON.parse(response.body)

        expect(response.status).to eq 404
        expect(result).to eq 'errors' => ['accounts.doesnt_exist']
      end
    end

    it 'unauthorized returns 401' do
      delete :destroy, params: { id: account.id }
      expect(response.code).to eq '401'
      expect(response.body).to eq 'Unauthorized'
    end
  end
end
