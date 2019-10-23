# frozen_string_literal: true
require "rails_helper"

RSpec.describe Exchange, type: :model do
  let(:exchange) { build(:exchange) }

  it { should validate_numericality_of(:rate) }

  it { should allow_value("http://locahost").for(:url) }

  it { should allow_value("http://locahost").for(:rest) }

  it { should allow_value("wss://localhost").for(:ws) }

  it { expect(exchange).to validate_inclusion_of(:name).in_array(Exchange::EXCHANGE_NAMES) }

  context "validations" do
    let(:valid_attributes) do
      {
        name: "bitfinex",
        url:  "https://bitifinex.com",
        rest: "https://bitifinex.com",
        ws:   "ws://bicoin.com",
        rate: 2

      }
    end

    it "creates valid record" do
      record = Exchange.new(valid_attributes)
      expect(record.save).to be_truthy
    end
  end

  context "invalid url" do
    let(:exchange) { build(:exchange, ws: "kek://lol.com") }

    it "creates valid record" do
      record = exchange
      expect(record.save).to be_falsy
    end
  end
end
