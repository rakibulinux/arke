describe ApiKeyService do
  let(:service) { ApiKeyService }
  let(:account) { create(:account) }
  let(:api_key) { { key: Faker::Number.hexadecimal(10), secret: Faker::Number.hexadecimal(20) } }
  let(:new_account) { create(:account) }
  let(:new_api_key) { { key: Faker::Number.hexadecimal(10), secret: Faker::Number.hexadecimal(20) } }

  before(:all) { WebMock.disable! }
  after(:all) { WebMock.enable! }

  context 'read' do
    before { service.create(account, api_key) }

    it 'reads api key correctly' do
      3.times do
        expect(service.read(account)).to eq api_key
        expect(service.read(new_account)).to be_nil
      end
    end
  end

  context 'create' do
    it 'creates api keys' do
      expect(service.exists?(account)).to be_falsey
      service.create(account, api_key)
      expect(service.exists?(account)).to be_truthy
    end

    it 'does not change created key' do
      service.create(account, api_key)
      service.create(account, new_api_key)

      expect(service.read(account)).to eq api_key
      expect(service.read(account)).not_to eq new_api_key
    end
  end

  context 'update' do
    before { service.create(account, api_key) }

    it 'updates existing api key' do
      service.update(account, new_api_key)

      expect(service.read(account)).not_to eq api_key
      expect(service.read(account)).to eq new_api_key
    end

    it 'does not create new api_key on update' do
      service.update(new_account, new_api_key)

      expect(service.read(account)).to eq api_key
      expect(service.read(new_account)).to be_nil
    end
  end

  context 'delete' do
    before { service.create(account, api_key) }

    it 'secret exists' do
      expect(service.delete(account)).to be_truthy
      expect(service.read(account)).to eq nil
    end

    it 'secret does nit exist' do
      expect(service.delete(new_account)).to be_falsey
      expect(service.read(new_account)).to eq nil
    end
  end
end
