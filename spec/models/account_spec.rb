# frozen_string_literal: true
require "rails_helper"

RSpec.describe Account, type: :model do
  it { should validate_presence_of(:name) }

  it { should validate_length_of(:name).is_at_least(3) }
  
  context "validations" do
    let(:exchange) { create(:exchange) }
    let(:user1) { create(:user) }
    let(:user2) { create(:user) }
    let(:user3) { create(:user) }
    let(:name1) { 'bitfaker1' }
    let(:name2) { 'B' }
  
    let(:valid_attributes) do
      {
        exchange_id:     exchange.id,
        name:            name1,
        user_id:         user1.id
      }
    end

    let(:attributes_short_name) do 
      {
        exchange_id:     exchange.id,
        name:            name2,
        user_id:         user2.id
      }
    end

    let(:attributes_skiped_name) do 
      {
        exchange_id:     exchange.id,
        user_id:         user3.id
      }
    end

    it "creates valid record" do
      record = Account.new(valid_attributes)
      expect(record.save).to be_truthy
    end

    it "creates record with too short name" do 
      record = Account.new(attributes_short_name)
      expect(record.save).to be_falsy
    end

    it "creates record without name field" do
      record = Account.new(attributes_skiped_name)
      expect(record.save).to be_falsy
    end

 
  end

end
