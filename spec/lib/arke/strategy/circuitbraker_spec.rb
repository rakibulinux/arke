# frozen_string_literal: true

require "rails_helper"

describe Arke::Strategy::Circuitbraker do
  let(:reactor) { double(:reactor) }
  let(:strategy) { Arke::Strategy::Circuitbraker.new([source], target, config, reactor) }
  let(:account) { Arke::Exchange.create(account_config) }
  let(:target_mode) { Arke::Helpers::Flags::DEFAULT_TARGET_FLAGS }
  let(:source_mode) { Arke::Helpers::Flags::DEFAULT_SOURCE_FLAGS }
  let(:source) { Arke::Market.new(config["sources"].first["market"], account, Arke::Helpers::Flags::DEFAULT_SOURCE_FLAGS) }
  let(:target) { Arke::Market.new(config["target"]["market"], account, target_mode) }
  let(:spread_asks) { 0.005 }
  let(:spread_bids) { 0.006 }
  let(:executor) { double(:executor) }

  let(:account_config) do
    {
      "id"     => 1,
      "driver" => "bitfaker",
    }
  end
  let(:config) do
    {
      "type"    => "circuitbraker",
      "params"  => {
        "spread_bids" => spread_bids,
        "spread_asks" => spread_asks,
      },
      "target"  => {
        "driver" => "bitfaker",
        "market" => {
          "id"              => "BTCUSD",
          "base"            => "BTC",
          "quote"           => "USD",
          "base_precision"  => 4,
          "quote_precision" => 4,
          "min_ask_amount"  => 0.001,
          "min_bid_amount"  => 0.001,
        },
      },
      "sources" => [
        "account_id" => 1,
        "market"     => {
          "id"    => "BTCUSD",
          "base"  => "BTC",
          "quote" => "USD",
        },
      ],
    }
  end
  before(:each) do
    source.update_orderbook
    target.account.fetch_balances
    target.account.executor = executor
  end

  context "orders are out of bounds" do
    it "cancels them" do
      order14 = Arke::Order.new("BTCUSD", 139.45, 1, :sell, "limit", 14)
      order15 = Arke::Order.new("BTCUSD", 135, 1, :sell, "limit", 15)
      order16 = Arke::Order.new("BTCUSD", 137.95, 1, :buy, "limit", 16)
      order17 = Arke::Order.new("BTCUSD", 140.95, 1, :buy, "limit", 17)

      target.add_order(order14)
      target.add_order(order15)
      target.add_order(order16)
      target.add_order(order17)

      expect(executor).to receive(:push).with(
        [
          Arke::Action.new(:order_stop, target, order: order15, priority: 1_000_000_004.5543),
          Arke::Action.new(:order_stop, target, order: order17, priority: 1_000_000_003.00268),
          Arke::Action.new(:order_stop, target, order: order14, priority: 1_000_000_000.1043),
          Arke::Action.new(:order_stop, target, order: order16, priority: 1_000_000_000.00268),
        ]
      )
      strategy.call
    end
  end

  context "no orders are out of bounds" do
    it "does nothing" do
      order14 = Arke::Order.new("BTCUSD", 139.56, 1, :sell, "limit", 14)
      order15 = Arke::Order.new("BTCUSD", 140, 1, :sell, "limit", 15)
      order16 = Arke::Order.new("BTCUSD", 137.93, 1, :buy, "limit", 16)
      order17 = Arke::Order.new("BTCUSD", 135.95, 1, :buy, "limit", 17)

      target.add_order(order14)
      target.add_order(order15)
      target.add_order(order16)
      target.add_order(order17)

      expect(executor).to_not receive(:push)
      strategy.call
    end
  end

  context "no open orders" do
    it "does nothing" do
      expect(executor).to_not receive(:push)
      strategy.call
    end
  end
end
