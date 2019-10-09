RSpec.describe Account, type: :model do
  let(:user) { create(:user) }
  let(:exchange) { create(:exchange) }
  let(:name) { 'BitFaker' }
  let(:params) { { user: user, exchange: exchange, name: name } }

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
  end

end
