#frozen_string_literal: true

require 'rails_helper'

RSpec.describe Balance, type: :model do

  it { should validate_inclusion_of(:currency).in_array(Balance::CURRENCY_NAME) }

  it { should validate_numericality_of(:amount) }

  it { should validate_numericality_of(:available) }

  it { should validate_numericality_of(:locked)}

  context "validations" do
    let(:account) { create(:account)}
    let(:user) { create(:user) }
    let(:echange) { create(:exchange) }

    let(:valid_attributes) do
      {
        account_id: account.id,
        currency: "usd",
        amount: 2,
        available: 2,
        locked: 2
      }
    end

    it "create valid record" do
      record = Balance.new(valid_attributes)
      expect(record.save).to be_truthy
    end
  end
end
