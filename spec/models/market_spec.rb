# frozen_string_literal: true
require "rails_helper"

RSpec.describe Market, type: :model do
  it { should validate_presence_of(:name) }

  it { should validate_presence_of(:base) }

  it { should validate_presence_of(:quote) }

  it { should validate_numericality_of(:base_precision) }

  it { should validate_numericality_of(:quote_precision) }

  it { should validate_numericality_of(:min_price) }

  it { should validate_numericality_of(:min_amount) }

  it { should validate_presence_of(:state) }

  context "validations" do
    let(:exchange) { create(:exchange) }

    let(:valid_attributes) do
      {
        exchange_id:     exchange.id,
        name:            :BTCUSD,
        base:            :USD,
        quote:           :BTC,
        base_precision:  1,
        quote_precision: 4,
        min_price:       100,
        min_amount:      10,
        state:           :disabled
      }
    end

    it "creates valid record" do
      record = Market.new(valid_attributes)
      expect(record.save).to be_truthy
    end
  end
end
