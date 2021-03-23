# frozen_string_literal: true


describe Arke::Strategy::Circuitbraker do
  let(:reactor) { double(:reactor) }
  let(:strategy) { Arke::Strategy::Circuitbraker.new([source], target, config, reactor) }
  let(:account) { Arke::Exchange.create(account_config) }
  let(:target_mode) { Arke::Helpers::Flags::DEFAULT_TARGET_FLAGS }
  let(:source_mode) { Arke::Helpers::Flags::DEFAULT_SOURCE_FLAGS }
  let(:source) { Arke::Market.new(config["sources"].first["market_id"], account, Arke::Helpers::Flags::DEFAULT_SOURCE_FLAGS) }
  let(:target) { Arke::Market.new(config["target"]["market_id"], account, target_mode) }
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
      "id"      => "circuitbraker-test",
      "type"    => "circuitbraker",
      "params"  => {
        "spread_bids" => spread_bids,
        "spread_asks" => spread_asks,
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
        "circuitbraker-test",
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

  context "with fx" do
    let(:fx) { ::Arke::Fx::Static.new(fx_config) }

    let(:fx_config) do
      {
        "type" => "static",
        "rate" => rate,
      }
    end

    let(:rate) { 10.0 }

    before(:each) do
      strategy.fx = fx
    end

    context "orders are out of bounds" do
      it "cancels them" do
        order14 = Arke::Order.new("BTCUSD", 1394.5, 1, :sell, "limit", 14)
        order15 = Arke::Order.new("BTCUSD", 1350, 1, :sell, "limit", 15)
        order16 = Arke::Order.new("BTCUSD", 1379.5, 1, :buy, "limit", 16)
        order17 = Arke::Order.new("BTCUSD", 1409.5, 1, :buy, "limit", 17)

        target.add_order(order14)
        target.add_order(order15)
        target.add_order(order16)
        target.add_order(order17)

        expect(executor).to receive(:push).with(
          "circuitbraker-test",
          [
            Arke::Action.new(:order_stop, target, order: order15, priority: "1_000_000_045.543".to_d),
            Arke::Action.new(:order_stop, target, order: order17, priority: "1_000_000_030.0268".to_d),
            Arke::Action.new(:order_stop, target, order: order14, priority: "1_000_000_001.043".to_d),
            Arke::Action.new(:order_stop, target, order: order16, priority: "1_000_000_000.0268".to_d),
          ]
        )
        strategy.call
      end
    end

    context "no orders are out of bounds" do
      it "does nothing" do
        order14 = Arke::Order.new("BTCUSD", 1395.6, 1, :sell, "limit", 14)
        order15 = Arke::Order.new("BTCUSD", 1400, 1, :sell, "limit", 15)
        order16 = Arke::Order.new("BTCUSD", 1379.3, 1, :buy, "limit", 16)
        order17 = Arke::Order.new("BTCUSD", 1359.5, 1, :buy, "limit", 17)

        target.add_order(order14)
        target.add_order(order15)
        target.add_order(order16)
        target.add_order(order17)

        expect(executor).to_not receive(:push)
        strategy.call
      end
    end
  end

  context "no open orders" do
    it "does nothing" do
      expect(executor).to_not receive(:push)
      strategy.call
    end
  end
end
