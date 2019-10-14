# frozen_string_literal: true

require "rails_helper"

describe Arke::Strategy::Fixedprice do
  let(:strategy) { Arke::Strategy::Fixedprice.new([], target, config, nil) }
  let(:account) { Arke::Exchange.create(config["target"]) }
  let(:target) { Arke::Market.new(config["target"]["market"], account) }

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
        "driver" => "bitfaker",
        "market" => {
          "id"             => "BTCUSD",
          "base"           => "BTC",
          "quote"          => "USD",
          "min_ask_amount" => 0.001,
          "min_bid_amount" => 0.001,
        },
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
  let(:target_bids) { target_orderbook[:buy] }
  let(:target_asks) { target_orderbook[:sell] }

  before(:each) do
    target.fetch_balances
  end

  context "running both sides" do
    let(:side) { "both" }
    it "outputs a target orberbook" do
      expect(target_bids.to_hash).to eq(
        120.49099999999997 => 0.0010000000000000009,
        120.50079999999998 => 0.12040000000000001,
        120.51059999999998 => 0.2398,
        120.52039999999998 => 0.35919999999999996,
        120.5302           => 0.47859999999999997
      )
      expect(target_asks.to_hash).to eq(
        124.24010000000001 => 0.3186,
        124.2502           => 0.23920000000000002,
        124.26030000000002 => 0.15980000000000003,
        124.27040000000002 => 0.08040000000000003,
        124.28050000000003 => 0.0010000000000000009
      )
    end
  end

  context "running asks side only" do
    let(:side) { "asks" }
    it "outputs a target orberbook" do
      expect(target_bids.to_hash).to eq({})
      expect(target_asks.to_hash).to eq(
        124.24010000000001 => 0.3186,
        124.2502           => 0.23920000000000002,
        124.26030000000002 => 0.15980000000000003,
        124.27040000000002 => 0.08040000000000003,
        124.28050000000003 => 0.0010000000000000009
      )
    end
  end

  context "running bids side only" do
    let(:side) { "bids" }
    it "outputs a target orberbook" do
      expect(target_bids.to_hash).to eq(
        120.49099999999997 => 0.0010000000000000009,
        120.50079999999998 => 0.12040000000000001,
        120.51059999999998 => 0.2398,
        120.52039999999998 => 0.35919999999999996,
        120.5302           => 0.47859999999999997
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
        122.94999999999997 => 0.0010000000000000009,
        122.95999999999998 => 0.12040000000000001,
        122.96999999999998 => 0.2398,
        122.97999999999999 => 0.35919999999999996,
        122.99             => 0.47859999999999997
      )
      expect(target_asks.to_hash).to eq(
        123.01             => 0.3186,
        123.02000000000001 => 0.23920000000000002,
        123.03000000000002 => 0.15980000000000003,
        123.04000000000002 => 0.08040000000000003,
        123.05000000000003 => 0.0010000000000000009
      )
    end
  end
end
