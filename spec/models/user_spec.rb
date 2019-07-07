require 'rails_helper'

RSpec.describe User, type: :model do

  let(:user) { build(:user) }

  context 'User Factory' do
    it 'should create a user' do
      expect {
        user.save!
      }.to_not raise_error
    end

    it 'should fail if is duplicate' do
      expect {
        user.save!
        User.create!(user.attributes)
      }.to raise_error(ActiveRecord::RecordNotUnique)
    end
  end
end
