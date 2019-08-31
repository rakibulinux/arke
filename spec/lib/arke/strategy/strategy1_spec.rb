require "rails_helper"

describe Arke::Strategy::Strategy1 do
  let(:strategy) { Arke::Strategy::Strategy1.new([source], target, config, nil, nil) }
  let(:source) { Arke::Exchange.create(config["sources"].first) }
  let(:target) { Arke::Exchange.create(config["target"]) }
  let(:side) { "both" }
  let(:spread_asks) { 0.01 }
  let(:spread_bids) { 0.02 }
  let(:limit_asks_base) { 1.0 }
  let(:limit_bids_base) { 1.5 }

  let(:config) do
    {
      "type" => "strategy1",
      "params" => {
        "spread_bids" => spread_bids,
        "spread_asks" => spread_asks,
        "limit_bids_base" => limit_bids_base,
        "limit_asks_base" => limit_asks_base,
        "levels_algo" => "constant",
        "levels_size" => 0.01,
        "levels_count" => 5,
        "side" => side,
      },
      "target" => {
        "driver" => "bitfaker",
        "market" => {
          "id" => "BTCUSD",
          "base" => "BTC",
          "quote" => "USD",
        },
      },
      "sources" => [
        "driver" => "bitfaker",
        "market" => {
          "id" => "BTCUSD",
          "base" => "BTC",
          "quote" => "USD",
        },
      ],
    }
  end

  let(:target_orderbook) { strategy.call }
  let(:target_bids) { target_orderbook[:buy] }
  let(:target_asks) { target_orderbook[:sell] }

  before do
    target.configure_market(config["target"]["market"])
    source.configure_market(config["sources"].first["market"])
  end

  before(:each) do
    source.fetch_balances
    target.fetch_balances
    source.start
  end

  context "running both sides" do
    let(:side) { "both" }
    it "outputs a target orberbook" do
      expect(target_bids.to_hash).to eq({
        135.926 => 0.7370333245680307,
        135.9652 => 0.026987961038240776,
        135.975 => 0.05791194830980497,
        135.98479999999998 => 0.08844010642949887,
        136.0044 => 0.5896266596544246,
      })
      expect(target_asks.to_hash).to eq({
        140.25738260869568 => 0.392750464457777,
        140.28900000000002 => 0.1426228573985294,
        140.2977264909 => 0.051228321451014386,
        140.32070728148 => 0.2011621370467299,
        140.3259222165 => 0.2122362196459493,
      })
    end
  end

  context "running asks side only" do
    let(:side) { "asks" }
    it "outputs a target orberbook" do
      expect(target_bids.to_hash).to eq({})
      expect(target_asks.to_hash).to eq({
        140.25738260869568 => 0.392750464457777,
        140.28900000000002 => 0.1426228573985294,
        140.2977264909 => 0.051228321451014386,
        140.32070728148 => 0.2011621370467299,
        140.3259222165 => 0.2122362196459493,
      })
    end
  end

  context "running bids side only" do
    let(:side) { "bids" }
    it "outputs a target orberbook" do
      expect(target_bids.to_hash).to eq({
        135.926 => 0.7370333245680307,
        135.9652 => 0.026987961038240776,
        135.975 => 0.05791194830980497,
        135.98479999999998 => 0.08844010642949887,
        136.0044 => 0.5896266596544246,
      })
      expect(target_asks.to_hash).to eq({})
    end
  end

  context "running both sides with a spread" do
    let(:side) { "both" }
    let(:spread_asks) { 0.01 }
    let(:spread_bids) { 0.02 }

    it "outputs a target orberbook" do
      expect(target_asks.to_hash).to eq({
        140.25738260869568 => 0.392750464457777,
        140.28900000000002 => 0.1426228573985294,
        140.2977264909 => 0.051228321451014386,
        140.32070728148 => 0.2011621370467299,
        140.3259222165 => 0.2122362196459493,
      })
      expect(target_bids.to_hash).to eq({
        135.926 => 0.7370333245680307,
        135.9652 => 0.026987961038240776,
        135.975 => 0.05791194830980497,
        135.98479999999998 => 0.08844010642949887,
        136.0044 => 0.5896266596544246,
      })
    end
  end

  context "running asks side only" do
    let(:side) { "asks" }
    let(:spread_asks) { 0.01 }
    let(:spread_bids) { 0.02 }

    it "outputs a target orberbook" do
      expect(target_asks.to_hash).to eq({
        140.25738260869568 => 0.392750464457777,
        140.28900000000002 => 0.1426228573985294,
        140.2977264909 => 0.051228321451014386,
        140.32070728148 => 0.2011621370467299,
        140.3259222165 => 0.2122362196459493,
      })
      expect(target_bids.to_hash).to eq({})
    end
  end

  context "running bids side only" do
    let(:side) { "bids" }
    let(:spread_asks) { 0.01 }
    let(:spread_bids) { 0.02 }

    it "outputs a target orberbook" do
      expect(target_bids.to_hash).to eq({
        135.926 => 0.7370333245680307,
        135.9652 => 0.026987961038240776,
        135.975 => 0.05791194830980497,
        135.98479999999998 => 0.08844010642949887,
        136.0044 => 0.5896266596544246,
      })

      expect(target_asks.to_hash).to eq({})
    end
  end

  context "callback method is functioning" do
    it "registers a callback" do
      strategy
      expect(target.instance_variable_get(:@trades_cb).length).to eq(1)
    end
  end
end
