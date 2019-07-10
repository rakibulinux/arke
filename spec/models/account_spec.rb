RSpec.describe Account, type: :model do
  let(:user) { create(:user) }
  let(:exchange) { create(:exchange) }
  let(:name) { 'MyAccount' }
  let(:api_key) { { key: key, secret: secret } }
  let(:key) { Faker::Number.hexadecimal(10) }
  let(:secret) { Faker::Number.hexadecimal(20) }
  let(:params) { { user: user, exchange: exchange, name: name, api_key: api_key } }

  before(:all) { WebMock.disable! }
  after(:all) { WebMock.enable! }


  context 'create' do
    it 'validates user' do
      expect {
        Account.create!(params.except(:user))
      }.to raise_error ActiveRecord::RecordInvalid
    end

    it 'validates name' do
      expect {
        Account.create!(params.except(:name))
      }.to raise_error ActiveRecord::RecordInvalid
    end

    it 'validates exchange' do
      expect {
        Account.create!(params.except(:exchange))
      }.to raise_error ActiveRecord::RecordInvalid
    end

    it 'requires api_key' do
      expect {
        Account.create!(params.except(:api_key))
      }.to raise_error ActiveRecord::RecordInvalid
    end

    it 'creates api_key after record saved in db' do
      expect(ApiKeyService).to receive(:create).and_return true
      expect { Account.create!(params) }.to change { Account.count }.by(1)
    end

    context 'validates api_key' do
      it 'requires secret' do
        new_params = params.except(:api_key).merge(api_key: { key: key })

        expect {
          Account.create!(new_params)
        }.to raise_error ActiveRecord::RecordInvalid
      end

      it 'requires key' do
        new_params = params.except(:api_key).merge(api_key: { secret: secret })

        expect {
          Account.create!(new_params)
        }.to raise_error ActiveRecord::RecordInvalid
      end

      it 'invalid params present' do
        new_params = params.merge(api_key: { key: key, secret: secret, smth: 'additional param' })

        expect {
          Account.create!(new_params)
        }.to raise_error ActiveRecord::RecordInvalid
      end
    end
  end

  context 'udpate' do
    let!(:account) { create(:account) }
    let(:new_api_key) { { key: 'new_key', secret: 'new_secret' } }

    it 'does not require api_key' do
      expect { account.update(name: 'new_name') }.to change { account.name }.to 'new_name'
    end

    it 'updates api_key if present' do
      expect { account.update(api_key: new_api_key) }.to change { account.api_key }.to new_api_key
    end

    context 'validates api_key' do
      it 'requires secret' do
        new_params = params.except(:api_key).merge(api_key: { key: key })

        expect {
          account.update!(new_params)
        }.to raise_error ActiveRecord::RecordInvalid
      end

      it 'requires key' do
        new_params = params.except(:api_key).merge(api_key: { secret: secret })

        expect {
          account.update!(new_params)
        }.to raise_error ActiveRecord::RecordInvalid
      end

      it 'invalid params present' do
        new_params = params.merge(api_key: { key: key, secret: secret, smth: 'additional param' })

        expect {
          account.update!(new_params)
        }.to raise_error ActiveRecord::RecordInvalid
      end
    end
  end

  context 'delete' do
    let!(:account) { create(:account) }

    it 'deletes api_key' do
      expect { account.destroy }.to change { account.api_key }.to nil
    end
  end
end
