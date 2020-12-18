# frozen_string_literal: true

describe Arke::Orderbook::Generator do
  let(:gen) { Arke::Orderbook::Generator }
  let(:shape) { "V" }
  let(:params) do
    {
      levels_count:      5,
      levels_price_size: 1,
      random:            0,
      market:            "abcusd",
      best_ask_price:    100,
      best_bid_price:    99,
      shape:             shape
    }
  end

  context "V shape" do
    let(:shape) { "V" }

    it do
      ob = gen.generate(params)
      expect(ob.book[:sell].to_hash).to eq(
        100.to_d => 1,
        101.to_d => 2,
        102.to_d => 3,
        103.to_d => 4,
        104.to_d => 5
      )
      expect(ob.book[:buy].to_hash).to eq(
        99.to_d => 1,
        98.to_d => 2,
        97.to_d => 3,
        96.to_d => 4,
        95.to_d => 5
      )
    end
  end

  context "W shape" do
    let(:shape) { "W" }

    it do
      ob = gen.generate(params)
      expect(ob.book[:sell].to_hash).to eq(
        100.to_d => 1,
        101.to_d => 2,
        102.to_d => 1,
        103.to_d => 2,
        104.to_d => 3
      )
      expect(ob.book[:buy].to_hash).to eq(
        99.to_d => 1,
        98.to_d => 2,
        97.to_d => 1,
        96.to_d => 2,
        95.to_d => 3
      )
    end
  end

end
