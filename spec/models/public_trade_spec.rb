# frozen_string_literal: true
require "rails_helper"

RSpec.describe PublicTrade, type: :model do
  let (:trade) do
    {
      id:         5,
      price:      3567.87,
      amount:     1414,
      total:      73276,
      taker_type: 'bid',
      exchange: 'binance',
      market:   'btcusdt',
      created_at: 125435167
    }
  end

  let (:top_keys) do
    [ :values, :tags, :timestamp ]
  end

  let (:values_keys) do
    [ :id, :price, :amount, :total, :taker_type ]
  end

  let (:tags_keys) do
    [ :exchange, :market ]
  end

  it { should validate_presence_of(:id) }

  it { should validate_presence_of(:market) }

  it { should validate_presence_of(:amount) }

  it { should validate_presence_of(:taker_type) }

  it { should validate_presence_of(:price) }

  it { should validate_presence_of(:total) }
  
  it { should validate_presence_of(:created_at) }

  it "return build_data" do
    record = PublicTrade.new(trade)
    result = record.build_data

    expect(result.keys).to contain_exactly(*top_keys)
    expect(result[:values].keys).to contain_exactly(*values_keys)
    expect(result[:tags].keys).to contain_exactly(*tags_keys)
  end
end
