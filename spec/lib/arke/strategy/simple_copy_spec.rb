# frozen_string_literal: true

describe Arke::Strategy::SimpleCopy do
  let(:reactor) { double(:reactor) }
  let(:executor) { double(:executor) }
  let(:strategy) { Arke::Strategy::SimpleCopy.new([source], target, config, reactor) }
  let(:account) { Arke::Exchange.create(account_config) }
  let(:target_mode) { Arke::Helpers::Flags::DEFAULT_TARGET_FLAGS }
  let(:source_mode) { Arke::Helpers::Flags::DEFAULT_SOURCE_FLAGS }
  let(:source) { Arke::Market.new(config["sources"].first["market_id"], account, Arke::Helpers::Flags::DEFAULT_SOURCE_FLAGS) }
  let(:target) { Arke::Market.new(config["target"]["market_id"], account, target_mode) }
  let(:spread_asks) { 0.005 }
  let(:spread_bids) { 0.006 }
  let(:levels_size) { 5.0 }
  let(:levels_count) { 10 }

  let(:account_config) do
    {
      "id"     => 1,
      "driver" => "bitfaker",
    }
  end
  let(:config) do
    {
      "type"    => "simple_copy",
      "params"  => {
        "spread_bids"  => spread_bids,
        "spread_asks"  => spread_asks,
        "levels_size"  => levels_size,
        "levels_count" => levels_count,
      },
      "target"  => {
        "driver"    => "bitfaker",
        "market_id" => "BTCUSD",
      },
      "sources" => [
        "account_id" => 1,
        "market_id"  => "BTCUSD",
      ],
    }
  end
  before(:each) do
    source.update_orderbook
    target.account.fetch_balances
    target.account.executor = executor
  end

  context "mid_price" do
    it "calculates mid_price from the source orderbook" do
      expect(strategy.mid_price).to eq(138.82)
    end
  end

  context "set_liquidity_limits" do
    it do
      strategy.set_liquidity_limits
      expect(strategy.limit_asks).to eq(4_723_846.89208129)
      expect(strategy.limit_bids).to eq(4_763_468.68006011)
    end
  end
end
