# frozen_string_literal: true

describe Arke::Orderbook::Generator do
  let(:gen) { Arke::Orderbook::Generator }
  let(:shape) { "V" }
  let(:levels) { nil }
  let(:params) do
    {
      levels_count:      5,
      levels_price_size: 1,
      random:            0,
      market:            "abcusd",
      best_ask_price:    100,
      best_bid_price:    99,
      shape:             shape,
      levels:            levels
    }
  end

  context "V shape" do
    let(:shape) { "V" }

    it do
      ob, pps = gen.generate(params)
      expect(ob.book[:sell].to_hash).to eq(
        100.to_d => 1,
        101.to_d => 2,
        102.to_d => 3,
        103.to_d => 4,
        104.to_d => 5
      )
      expect(pps[:asks]).to eq(
        [
          ::Arke::PricePoint.new(100),
          ::Arke::PricePoint.new(101),
          ::Arke::PricePoint.new(102),
          ::Arke::PricePoint.new(103),
          ::Arke::PricePoint.new(104)
        ]
      )
      expect(ob.book[:buy].to_hash).to eq(
        99.to_d => 1,
        98.to_d => 2,
        97.to_d => 3,
        96.to_d => 4,
        95.to_d => 5
      )
      expect(pps[:bids]).to eq(
        [
          ::Arke::PricePoint.new(99),
          ::Arke::PricePoint.new(98),
          ::Arke::PricePoint.new(97),
          ::Arke::PricePoint.new(96),
          ::Arke::PricePoint.new(95)
        ]
      )
    end
  end

  context "W shape" do
    let(:shape) { "W" }

    it do
      ob, pps = gen.generate(params)
      expect(ob.book[:sell].to_hash).to eq(
        100.to_d => 1,
        101.to_d => 2,
        102.to_d => 1,
        103.to_d => 2,
        104.to_d => 3
      )
      expect(pps[:asks]).to eq(
        [
          ::Arke::PricePoint.new(100),
          ::Arke::PricePoint.new(101),
          ::Arke::PricePoint.new(102),
          ::Arke::PricePoint.new(103),
          ::Arke::PricePoint.new(104)
        ]
      )
      expect(ob.book[:buy].to_hash).to eq(
        99.to_d => 1,
        98.to_d => 2,
        97.to_d => 1,
        96.to_d => 2,
        95.to_d => 3
      )
      expect(pps[:bids]).to eq(
        [
          ::Arke::PricePoint.new(99),
          ::Arke::PricePoint.new(98),
          ::Arke::PricePoint.new(97),
          ::Arke::PricePoint.new(96),
          ::Arke::PricePoint.new(95)
        ]
      )
    end
  end

  context "custom shape" do
    let(:shape) { "custom" }
    let(:levels) do
      [0.1, 1, 2, 0.1]
    end
    it do
      ob, pps = gen.generate(params)
      expect(ob.book[:sell].to_hash).to eq(
        100.to_d => 0.1,
        101.to_d => 1,
        102.to_d => 2,
        103.to_d => 0.1,
        104.to_d => 0.1
      )
      expect(pps[:asks]).to eq(
        [
          ::Arke::PricePoint.new(100),
          ::Arke::PricePoint.new(101),
          ::Arke::PricePoint.new(102),
          ::Arke::PricePoint.new(103),
          ::Arke::PricePoint.new(104)
        ]
      )
      expect(ob.book[:buy].to_hash).to eq(
        99.to_d => 0.1,
        98.to_d => 1,
        97.to_d => 2,
        96.to_d => 0.1,
        95.to_d => 0.1
      )
      expect(pps[:bids]).to eq(
        [
          ::Arke::PricePoint.new(99),
          ::Arke::PricePoint.new(98),
          ::Arke::PricePoint.new(97),
          ::Arke::PricePoint.new(96),
          ::Arke::PricePoint.new(95)
        ]
      )
    end
  end
end
