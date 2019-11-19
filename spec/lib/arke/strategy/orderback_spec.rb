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
  let(:target_bids) { target_orderbook.first[:buy] }
  let(:target_asks) { target_orderbook.first[:sell] }

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
        135.9554.to_d => 0.95982849262347e-2.to_d,
        135.9652.to_d => 0.052719082907474284.to_d,
        135.9750.to_d => (11_312_691_610_721_95.to_d * 1e-16),
        135.9848.to_d => (1_727_615_249_109_062.to_d * 1e-16),
        136.0044.to_d => (11_517_941_911_481_652.to_d * 1e-16)
      )
      expect(target_asks.to_hash).to eq(
        (1_402_573_826_086_956_521.to_d * 1e-16) => (6656597259005248.to_d * 1e-16),
        140.2688.to_d                            => 0.0028941727213066.to_d,
        140.2789.to_d                            => 0.0028941727213066.to_d,
        140.2890.to_d                            => 0.241726747017663.to_d,
        140.2977264909.to_d                      => 0.0868251816391989.to_d
      )
    end
  end

  context "running asks side only" do
    let(:side) { "asks" }
    it "outputs a target orberbook" do
      expect(target_bids.to_hash).to eq({})
      expect(target_asks.to_hash).to eq(
        (1_402_573_826_086_956_521.to_d * 1e-16) => (6_656_597_259_005_248.to_d * 1e-16),
        0.1402688e3.to_d                         => 0.28941727213066e-2.to_d,
        0.1402789e3.to_d                         => 0.28941727213066e-2.to_d,
        0.140289e3.to_d                          => 0.241726747017663e0.to_d,
        0.1402977264909e3.to_d                   => 0.868251816391989e-1.to_d
      )
    end
  end

  context "running bids side only" do
    let(:side) { "bids" }
    it "outputs a target orberbook" do
      expect(target_bids.to_hash).to eq(
        135.9554.to_d => 0.95982849262347e-2.to_d,
        135.9652.to_d => 0.527190829074743e-1.to_d,
        135.9750.to_d => (1_131_269_161_072_195.to_d * 1e-16),
        135.9848.to_d => (1_727_615_249_109_062.to_d * 1e-16),
        136.0044.to_d => (11_517_941_911_481_652.to_d * 1e-16)
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
        (1_402_573_826_086_956_521.to_d * 1e-16) => (6_656_597_259_005_248.to_d * 1e-16),
        0.1402688e3.to_d                         => 0.28941727213066e-2.to_d,
        0.1402789e3.to_d                         => 0.28941727213066e-2.to_d,
        0.140289e3.to_d                          => 0.241726747017663e0.to_d,
        0.1402977264909e3.to_d                   => 0.868251816391989e-1.to_d
      )
      expect(target_bids.to_hash).to eq(
        135.9554.to_d => 0.95982849262347e-2.to_d,
        135.9652.to_d => 0.527190829074743e-1.to_d,
        135.9750.to_d => (1_131_269_161_072_195.to_d * 1e-16),
        135.9848.to_d => (1_727_615_249_109_062.to_d * 1e-16),
        136.0044.to_d => (11_517_941_911_481_652.to_d * 1e-16)
      )
    end
  end

  context "running asks side only" do
    let(:side) { "asks" }
    let(:spread_asks) { 0.01 }
    let(:spread_bids) { 0.02 }

    it "outputs a target orberbook" do
      expect(target_asks.to_hash).to eq(
        (1_402_573_826_086_956_521.to_d * 1e-16) => (6_656_597_259_005_248.to_d * 1e-16),
        0.1402688e3.to_d                         => 0.28941727213066e-2.to_d,
        0.1402789e3.to_d                         => 0.28941727213066e-2.to_d,
        0.140289e3.to_d                          => 0.241726747017663e0.to_d,
        0.1402977264909e3.to_d                   => 0.868251816391989e-1.to_d
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
        135.9554.to_d => 0.95982849262347e-2.to_d,
        135.9652.to_d => 0.527190829074743e-1.to_d,
        135.9750.to_d => 1_131_269_161_072_195.to_d * 1e-16,
        135.9848.to_d => 1_727_615_249_109_062.to_d * 1e-16,
        136.0044.to_d => 11_517_941_911_481_652.to_d * 1e-16
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
