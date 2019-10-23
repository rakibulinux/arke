# frozen_string_literal: true

require 'rails_helper'

RSpec.describe User, type: :model do

  it { should validate_presence_of(:uid) }

  it { should validate_presence_of(:email) }

  it { should validate_presence_of(:level) }

  it { should validate_presence_of(:role) }

  it { should validate_numericality_of(:level) }

  it { should validate_presence_of(:state) }

  it { should validate_presence_of(:created_at) }

  let(:user) { build(:user) }

  context 'validation' do
    let(:validate_params) do
    {
      uid: 'ID123456',
      email: 'lolkek@cheburek.com',
      level: 1,
      role: 'John Doe',
      state: 'active',
      created_at: '2008-10-29 11:10:01',
      updated_at: '2008-11-11 11:12:01'
    }
    end

    it 'should create a user' do
      expect {
        user.save!
      }.to_not raise_error
    end

    it 'should fail due to duplication' do
      expect {
        user.save!
        User.create!(user.attributes)
      }.to raise_error(ActiveRecord::RecordInvalid)
    end

    it 'role should raise error' do 
      expect {
        user = User.new(validate_params)
        user.save!
      }.to raise_error(ActiveRecord::RecordInvalid)
    end
  end
end
