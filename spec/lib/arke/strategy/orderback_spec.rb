# frozen_string_literal: true

require "rails_helper"

describe Arke::Strategy::Orderback do
  let!(:strategy) { Arke::Strategy::Orderback.new([source], target, config, nil) }
  let(:account) { Arke::Exchange.create(account_config) }
  let(:source) { Arke::Market.new(config["sources"].first["market"], account, Arke::Helpers::Flags::DEFAULT_SOURCE_FLAGS) }
  let(:target) { Arke::Market.new(config["target"]["market"], account, Arke::Helpers::Flags::DEFAULT_TARGET_FLAGS) }
  let(:side) { "both" }
  let(:spread_asks) { 0.01 }
  let(:spread_bids) { 0.02 }
  let(:limit_asks_base) { 1.0 }
  let(:limit_bids_base) { 1.5 }

  let(:config) do
    {
      "type"    => "orderback",
      "params"  => {
        "spread_bids"           => spread_bids,
        "spread_asks"           => spread_asks,
        "limit_bids_base"       => limit_bids_base,
        "limit_asks_base"       => limit_asks_base,
        "levels_algo"           => "constant",
        "levels_size"           => 0.01,
        "levels_count"          => 5,
        "side"                  => side,
        "min_order_back_amount" => 0.001,
      },
      "target"  => {
        "account_id" => 1,
        "market"     => {
          "id"             => "BTCUSD",
          "base"           => "BTC",
          "quote"          => "USD",
          "min_ask_amount" => 0.1,
          "min_bid_amount" => 0.1,
        },
      },
      "sources" => [
        "account_id" => 1,
        "market"     => {
          "id"             => "BTCUSD",
          "base"           => "BTC",
          "quote"          => "USD",
          "min_ask_amount" => 0.001,
          "min_bid_amount" => 0.001,
        },
      ],
    }
  end

  let(:account_config) do
    {
      "id"     => 1,
      "driver" => "bitfaker",
    }
  end
  let(:target_orderbook) { strategy.call }
  let(:target_bids) { target_orderbook[:buy] }
  let(:target_asks) { target_orderbook[:sell] }

  before(:each) do
    source.account.fetch_balances
    target.account.fetch_balances
    source.start
    source.update_orderbook
  end

  context "running both sides" do
    let(:side) { "both" }
    it "outputs a target orberbook" do
      expect(target_bids.to_hash).to eq(
        135.9652           => 0.052719082907474284,
        135.975            => 0.11312691610721952,
        135.98479999999998 => 0.1727615249109062,
        135.9848           => 0.00959828492623471,
        136.0044           => 1.151794191148165
      )
      expect(target_asks.to_hash).to eq(
        140.25738260869568 => 0.6637387513124022,
        140.2688           => 0.00288582065788001,
        140.2789           => 0.00288582065788001,
        140.289            => 0.00288582065788001,
        140.29130611690687 => 0.3276037867139576
      )
    end
  end

  context "running asks side only" do
    let(:side) { "asks" }
    it "outputs a target orberbook" do
      expect(target_bids.to_hash).to eq({})
      expect(target_asks.to_hash).to eq(
        140.25738260869568 => 0.6637387513124022,
        140.2688           => 0.00288582065788001,
        140.2789           => 0.00288582065788001,
        140.289            => 0.00288582065788001,
        140.29130611690687 => 0.3276037867139576
      )
    end
  end

  context "running bids side only" do
    let(:side) { "bids" }
    it "outputs a target orberbook" do
      expect(target_bids.to_hash).to eq(
        135.9652           => 0.052719082907474284,
        135.975            => 0.11312691610721952,
        135.98479999999998 => 0.1727615249109062,
        135.9848           => 0.00959828492623471,
        136.0044           => 1.151794191148165
      )
      expect(target_asks.to_hash).to eq({})
    end
  end

  context "running both sides with a spread" do
    let(:side) { "both" }
    let(:spread_asks) { 0.01 }
    let(:spread_bids) { 0.02 }

    it "outputs a target orberbook" do
      expect(target_asks.to_hash).to eq(
        140.25738260869568 => 0.6637387513124022,
        140.2688           => 0.00288582065788001,
        140.2789           => 0.00288582065788001,
        140.289            => 0.00288582065788001,
        140.29130611690687 => 0.3276037867139576
      )
      expect(target_bids.to_hash).to eq(
        135.9652           => 0.052719082907474284,
        135.975            => 0.11312691610721952,
        135.98479999999998 => 0.1727615249109062,
        135.9848           => 0.00959828492623471,
        136.0044           => 1.151794191148165
      )
    end
  end

  context "running asks side only" do
    let(:side) { "asks" }
    let(:spread_asks) { 0.01 }
    let(:spread_bids) { 0.02 }

    it "outputs a target orberbook" do
      expect(target_asks.to_hash).to eq(
        140.25738260869568 => 0.6637387513124022,
        140.2688           => 0.00288582065788001,
        140.2789           => 0.00288582065788001,
        140.289            => 0.00288582065788001,
        140.29130611690687 => 0.3276037867139576
      )
      expect(target_bids.to_hash).to eq({})
    end
  end

  context "running bids side only" do
    let(:side) { "bids" }
    let(:spread_asks) { 0.01 }
    let(:spread_bids) { 0.02 }

    it "outputs a target orberbook" do
      expect(target_bids.to_hash).to eq(
        135.9652           => 0.052719082907474284,
        135.975            => 0.11312691610721952,
        135.98479999999998 => 0.1727615249109062,
        135.9848           => 0.00959828492623471,
        136.0044           => 1.151794191148165
      )

      expect(target_asks.to_hash).to eq({})
    end
  end

  context "callback method is functioning" do
    it "registers a callback" do
      strategy
      expect(target.account.instance_variable_get(:@private_trades_cb).length).to eq(1)
    end
  end
end
