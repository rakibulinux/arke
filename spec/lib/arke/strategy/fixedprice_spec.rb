require "rails_helper"

describe Arke::Strategy::Fixedprice do
  let(:strategy) { Arke::Strategy::Fixedprice.new([], target, config, nil) }
  let(:target) { Arke::Exchange.create(config["target"]) }
  let(:price) { 123 }
  let(:random_delta) { 0 }
  let(:side) { "both" }
  let(:spread_asks) { 0.01 }
  let(:spread_bids) { 0.02 }
  let(:limit_asks_base) { 1.0 }
  let(:limit_bids_base) { 1.5 }

  let(:config) do
    {
      "type" => "fixedprice",
      "params" => {
        "price" => price,
        "random_delta" => random_delta,
        "spread_bids" => spread_bids,
        "spread_asks" => spread_asks,
        "limit_bids_base" => limit_bids_base,
        "limit_asks_base" => limit_asks_base,
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
      }
    }
  end

  let(:target_config) do
    {
      "driver" => "rubykube",
      "host" => "http://www.example.com",
      "key" => nil,
      "secret" => nil,
    }
  end

  let(:target_orderbook) { strategy.call }
  let(:target_bids) { target_orderbook[:buy] }
  let(:target_asks) { target_orderbook[:sell] }

  before(:each) do
    target.fetch_balances
  end

  context "running both sides" do
    let(:side) { "both" }
    it "outputs a target orberbook" do
      expect(target_bids.to_hash).to eq({
        120.49099999999997 => 0.3,
        120.50079999999998 => 0.3,
        120.51059999999998 => 0.3,
        120.52039999999998 => 0.3,
        120.5302 => 0.3,
      })
      expect(target_asks.to_hash).to eq({
        124.24010000000001 => 0.2,
        124.2502 => 0.2,
        124.26030000000002 => 0.2,
        124.27040000000002 => 0.2,
        124.28050000000003 => 0.2,
      })
    end
  end

  context "running asks side only" do
    let(:side) { "asks" }
    it "outputs a target orberbook" do
      expect(target_bids.to_hash).to eq({})
      expect(target_asks.to_hash).to eq({
        124.24010000000001 => 0.2,
        124.2502 => 0.2,
        124.26030000000002 => 0.2,
        124.27040000000002 => 0.2,
        124.28050000000003 => 0.2,
      })
    end
  end

  context "running bids side only" do
    let(:side) { "bids" }
    it "outputs a target orberbook" do
      expect(target_bids.to_hash).to eq({
        120.49099999999997 => 0.3,
        120.50079999999998 => 0.3,
        120.51059999999998 => 0.3,
        120.52039999999998 => 0.3,
        120.5302 => 0.3,
      })
      expect(target_asks.to_hash).to eq({})
    end
  end

  context "running both sides without spread" do
    let(:side) { "both" }
    let(:spread_asks) { 0 }
    let(:spread_bids) { 0 }

    it "outputs a target orberbook" do
      expect(target_bids.to_hash).to eq({
        122.94999999999997 => 0.3,
        122.95999999999998 => 0.3,
        122.96999999999998 => 0.3,
        122.97999999999999 => 0.3,
        122.99 => 0.3,
      })
      expect(target_asks.to_hash).to eq({
        123.01 => 0.2,
        123.02000000000001 => 0.2,
        123.03000000000002 => 0.2,
        123.04000000000002 => 0.2,
        123.05000000000003 => 0.2,
      })
    end
  end

  context "callback method is functioning" do
    it "registers a callback" do
      strategy
      expect(target.instance_variable_get(:@trades_cb).length).to eq(1)
    end
  end
end
