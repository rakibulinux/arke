# frozen_string_literal: true


describe Arke::Strategy::Fixedprice do
  let(:strategy) { Arke::Strategy::Fixedprice.new([], target, config, nil) }
  let(:account) { Arke::Exchange.create(config["target"]) }
  let(:target) { Arke::Market.new(config["target"]["market_id"], account) }

  let(:price) { 123 }
  let(:random_delta) { 0 }
  let(:side) { "both" }
  let(:spread_asks) { 0.01 }
  let(:spread_bids) { 0.02 }
  let(:limit_asks_base) { 1.0 }
  let(:limit_bids_base) { 1.5 }

  let(:config) do
    {
      "type"   => "fixedprice",
      "params" => {
        "price"           => price,
        "random_delta"    => random_delta,
        "spread_bids"     => spread_bids,
        "spread_asks"     => spread_asks,
        "limit_bids_base" => limit_bids_base,
        "limit_asks_base" => limit_asks_base,
        "levels_size"     => 0.01,
        "levels_count"    => 5,
        "side"            => side,
      },
      "target" => {
        "driver"    => "bitfaker",
        "market_id" => "BTCUSD",
      }
    }
  end

  let(:target_config) do
    {
      "driver" => "rubykube",
      "host"   => "http://www.example.com",
      "key"    => nil,
      "secret" => nil,
    }
  end

  let(:target_orderbook) { strategy.call }
  let(:target_bids) { target_orderbook.first[:buy] }
  let(:target_asks) { target_orderbook.first[:sell] }

  before(:each) do
    target.fetch_balances
  end

  context "running both sides" do
    let(:side) { "both" }
    it "outputs a target orberbook" do
      expect(target_bids.to_hash).to eq(
        120.4910.to_d => "0.1363636363636364".to_d,
        120.5008.to_d => "0.2181818181818182".to_d,
        120.5106.to_d => "0.3".to_d,
        120.5204.to_d => "0.3818181818181818".to_d,
        120.5302.to_d => "0.4636363636363636".to_d
      )
      expect(target_asks.to_hash).to eq(
        124.2401.to_d => "0.257142857".to_d,
        124.2502.to_d => "0.228571429".to_d,
        124.2603.to_d => "0.2".to_d,
        124.2704.to_d => "0.171428571".to_d,
        124.2805.to_d => "0.142857143".to_d
      )
    end
  end

  context "running asks side only" do
    let(:side) { "asks" }
    it "outputs a target orberbook" do
      expect(target_bids.to_hash).to eq({})
      expect(target_asks.to_hash).to eq(
        124.2401.to_d => "0.257142857".to_d,
        124.2502.to_d => "0.228571429".to_d,
        124.2603.to_d => "0.2".to_d,
        124.2704.to_d => "0.171428571".to_d,
        124.2805.to_d => "0.142857143".to_d
      )
    end
  end

  context "running bids side only" do
    let(:side) { "bids" }
    it "outputs a target orberbook" do
      expect(target_bids.to_hash).to eq(
        120.4910.to_d => "0.1363636363636364".to_d,
        120.5008.to_d => "0.2181818181818182".to_d,
        120.5106.to_d => "0.3".to_d,
        120.5204.to_d => "0.3818181818181818".to_d,
        120.5302.to_d => "0.4636363636363636".to_d
      )
      expect(target_asks.to_hash).to eq({})
    end
  end

  context "running both sides without spread" do
    let(:side) { "both" }
    let(:spread_asks) { 0 }
    let(:spread_bids) { 0 }

    it "outputs a target orberbook" do
      expect(target_bids.to_hash).to eq(
        122.95.to_d => "0.1363636363636364".to_d,
        122.96.to_d => "0.2181818181818182".to_d,
        122.97.to_d => "0.3".to_d,
        122.98.to_d => "0.3818181818181818".to_d,
        122.99.to_d => "0.4636363636363636".to_d
      )

      expect(target_asks.to_hash).to eq(
        123.01.to_d => "0.257142857".to_d,
        123.02.to_d => "0.228571429".to_d,
        123.03.to_d => "0.2".to_d,
        123.04.to_d => "0.171428571".to_d,
        123.05.to_d => "0.142857143".to_d
      )
    end
  end

  context "requested volume is low compared to market min order amount" do
    let(:side) { "both" }
    let(:limit_asks_base) { 0.002 }
    let(:limit_bids_base) { 0.002 }

    it "outputs a target orberbook" do
      expect(target_bids.to_hash).to eq(
        120.4910.to_d => 0.0004.to_d,
        120.5008.to_d => 0.0004.to_d,
        120.5106.to_d => 0.0004.to_d,
        120.5204.to_d => 0.0004.to_d,
        120.5302.to_d => 0.0004.to_d
      )
      expect(target_asks.to_hash).to eq(
        124.2401.to_d => 0.0004.to_d,
        124.2502.to_d => 0.0004.to_d,
        124.2603.to_d => 0.0004.to_d,
        124.2704.to_d => 0.0004.to_d,
        124.2805.to_d => 0.0004.to_d
      )
    end
  end
end
