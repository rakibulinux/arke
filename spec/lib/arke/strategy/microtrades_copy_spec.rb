# frozen_string_literal: true

require "rails_helper"

describe Arke::Strategy::MicrotradesCopy do
  let(:reactor) { double(:reactor) }
  let(:strategy) { Arke::Strategy::MicrotradesCopy.new([source], target, config, reactor) }
  let(:account) { Arke::Exchange.create(account_config) }
  let(:target_mode) { Arke::Helpers::Flags::DEFAULT_TARGET_FLAGS }
  let(:source_mode) { Arke::Helpers::Flags::DEFAULT_SOURCE_FLAGS }
  let(:source) { Arke::Market.new(config["sources"].first["market_id"], source_account, Arke::Helpers::Flags::DEFAULT_SOURCE_FLAGS) }
  let(:target) { Arke::Market.new(config["target"]["market_id"], account, target_mode) }
  let(:min_amount) { 350 }
  let(:max_amount) { 400 }
  let(:period) { 15 }
  let(:period_random) { 5 }

  let(:account_config) do
    {
      "id"        => 1,
      "driver"    => "bitfaker",
      "orderbook" => orderbook,
    }
  end
  let(:fx_config) { nil }
  let(:config) do
    {
      "type"                => "microtrades-copy",
      "period"              => period,
      "period_random_delay" => period_random,
      "fx"                  => fx_config,
      "params"              => {
        "min_amount"               => min_amount,
        "max_amount"               => max_amount,
        "maker_taker_orders_delay" => 0.01,
        "matching_timeout"         => 0.01,
      },
      "target"              => {
        "driver"    => "bitfaker",
        "market_id" => "BTCUSD",
      },
      "sources"             => [
        {
          "driver"    => "bitfaker",
          "market_id" => "XBTUSDT",
        }
      ],
    }
  end
  let(:orderbook) do
    [
      nil,
      [
        [22_847_510_020, 10_030, -0.2],
        [22_847_510_020, 10_020, -0.90403],
        [22_847_510_020, 10_010, -0.73563],
        [22_847_510_020, 9980, 0.20603],
        [22_847_510_020, 9970, 0.09944],
        [22_847_510_020, 9960, 0.05057],
      ]
    ]
  end
  let(:target_orderbook) { strategy.call }
  let(:target_bids) { target_orderbook[:buy] }
  let(:target_asks) { target_orderbook[:sell] }

  before(:each) do
    target.account.fetch_balances
    if config["fx"]
      type = config["fx"]["type"]
      fx_klass = Arke::Fx.const_get(type.capitalize)
      strategy.fx = fx_klass.new(config["fx"])
    end
  end

  context "wrong configuration" do
  end

  context "strategy execution" do
    let(:source) { Arke::Market.new("XBTUSDT", account, source_mode) }
    let(:min_amount) { 10 }
    let(:max_amount) { 10 }

    context "set expiration time" do
      it "is min now + delay and max now + delay + random" do
        now = Time.now.to_i
        exp = strategy.instance_variable_get(:@expiration)
        expect(exp).to be_between(now + period, now + period + period_random).exclusive
      end
    end

    let(:public_trade) { ::Arke::PublicTrade.new(42, "XBTUSDT", "kraken", "buy", 0.1, 9999, 999.9) }

    context "expiration time is not reached" do
      it "creates a buy order on the target" do
        expect(target.account).to_not receive(:create_order)
        strategy.instance_variable_set(:@expiration, Time.now.to_i + 10)

        EM.synchrony do
          strategy.on_trade(source.id, public_trade)
          EM::Synchrony.add_timer(0.011) { EM.stop }
        end
      end
    end

    context "expiration time is reached" do
      it "creates a sell maker order on the target" do
        expect(target.account).to receive(:create_order).with(::Arke::Order.new("BTCUSD", 9999, 10, :sell, "limit"))
        strategy.instance_variable_set(:@expiration, Time.now.to_i - 10)

        EM.synchrony do
          strategy.on_trade(source.id, public_trade)
          EM.stop
        end
      end

      it "creates a sell order and take it with a buy order on the target" do
        expect(target.account).to receive(:create_order).with(::Arke::Order.new("BTCUSD", 9999, 10, :sell, "limit")).ordered
        expect(target.account).to receive(:create_order).with(::Arke::Order.new("BTCUSD", 9999, 10, :buy, "limit")).ordered
        strategy.instance_variable_set(:@expiration, Time.now.to_i - 10)

        EM.synchrony do
          strategy.on_trade(source.id, public_trade)
          EM::Synchrony.add_timer(0.011) { EM.stop }
        end
      end

      it "cancels orders if they have not been marched before the timeout" do
        expect(target.account).to receive(:create_order).with(::Arke::Order.new("BTCUSD", 9999, 10, :sell, "limit")).ordered
        expect(target.account).to receive(:create_order).with(::Arke::Order.new("BTCUSD", 9999, 10, :buy, "limit")).ordered
        strategy.instance_variable_set(:@expiration, Time.now.to_i - 10)

        sell = ::Arke::Order.new("BTCUSD", 9999, 10, :sell, "limit", 10)
        buy = ::Arke::Order.new("BTCUSD", 9999, 10, :buy, "limit", 11)
        strategy.target.add_order(sell)
        strategy.target.add_order(buy)
        expect(target.account).to receive(:stop_order).with(sell).ordered
        expect(target.account).to receive(:stop_order).with(buy).ordered

        EM.synchrony do
          strategy.on_trade(source.id, public_trade)
          EM::Synchrony.add_timer(0.03) { EM.stop }
        end
      end
    end

    context "trade price is higher than the best ask" do
      let(:public_trade) { ::Arke::PublicTrade.new(42, "XBTUSDT", "kraken", "buy", 0.1, 10_015, 1001.5) }
      let(:orderbook) do
        [
          nil,
          [
            [22_847_510_020, 10_020, -0.90403],
            [22_847_510_020, 10_010, -0.73563],
            [22_847_510_020, 9980, 0.20603],
            [22_847_510_020, 9970, 0.09944],
          ]
        ]
      end

      it "creates a sell order and take it with a buy order on the target" do
        expect(target.account).to receive(:create_order).with(::Arke::Order.new("BTCUSD", 10_009.999999, 10, :sell, "limit")).ordered
        expect(target.account).to receive(:create_order).with(::Arke::Order.new("BTCUSD", 10_009.999999, 10, :buy, "limit")).ordered
        strategy.instance_variable_set(:@expiration, Time.now.to_i - 10)

        EM.synchrony do
          strategy.on_trade(source.id, public_trade)
          EM::Synchrony.add_timer(0.011) { EM.stop }
        end
      end
    end

    context "trade price is lower than the best bid" do
      let(:public_trade) { ::Arke::PublicTrade.new(42, "XBTUSDT", "kraken", "buy", 0.1, 9975, 997.5) }
      let(:orderbook) do
        [
          nil,
          [
            [22_847_510_020, 10_020, -0.90403],
            [22_847_510_020, 10_010, -0.73563],
            [22_847_510_020, 9980, 0.20603],
            [22_847_510_020, 9970, 0.09944],
          ]
        ]
      end

      it "creates a sell order and take it with a buy order on the target" do
        expect(target.account).to receive(:create_order).with(::Arke::Order.new("BTCUSD", 9980.000001, 10, :sell, "limit")).ordered
        expect(target.account).to receive(:create_order).with(::Arke::Order.new("BTCUSD", 9980.000001, 10, :buy, "limit")).ordered
        strategy.instance_variable_set(:@expiration, Time.now.to_i - 10)

        EM.synchrony do
          strategy.on_trade(source.id, public_trade)
          EM::Synchrony.add_timer(0.011) { EM.stop }
        end
      end
    end

    context "trade market is not the one configured" do
      let(:public_trade) { ::Arke::PublicTrade.new(42, "XBTETH", "kraken", "buy", 0.1, 139, 13.9) }
      it "does not create any order" do
        expect(target.account).to_not receive(:create_order)
        strategy.instance_variable_set(:@expiration, Time.now.to_i - 10)

        EM.synchrony do
          strategy.on_trade(source.id, public_trade)
          EM::Synchrony.add_timer(0.011) { EM.stop }
        end
      end
    end

    context "trade market case is different that the one configured" do
      let(:public_trade) { ::Arke::PublicTrade.new(42, "xbtusdt", "kraken", "buy", 0.1, 9985, nil) }
      it "does not create any order" do
        expect(target.account).to receive(:create_order).with(::Arke::Order.new("BTCUSD", 9985, 10, :sell, "limit")).ordered
        expect(target.account).to receive(:create_order).with(::Arke::Order.new("BTCUSD", 9985, 10, :buy, "limit")).ordered
        strategy.instance_variable_set(:@expiration, Time.now.to_i - 10)

        EM.synchrony do
          strategy.on_trade(source.id, public_trade)
          EM::Synchrony.add_timer(0.011) { EM.stop }
        end
      end
    end

    context "spread is too small" do
      let(:public_trade) { ::Arke::PublicTrade.new(42, "XBTUSDT", "kraken", "buy", 0.1, 9975, 997.5) }
      let(:orderbook) do
        [
          nil,
          [
            [22_847_510_020, 10_020, -0.90403],
            [22_847_510_020, 10_000, -0.73563],
            [22_847_510_020, 9999.999999, 0.20603],
            [22_847_510_020, 9970, 0.09944],
          ]
        ]
      end

      it "creates a sell order and take it with a buy order on the target" do
        expect(target.account).to_not receive(:create_order)
        strategy.instance_variable_set(:@expiration, Time.now.to_i - 10)

        EM.synchrony do
          strategy.on_trade(source.id, public_trade)
          EM::Synchrony.add_timer(0.011) { EM.stop }
        end
      end
    end

    context "strategy with fx" do
      let(:fx_config) do
        {
          "type" => "static",
          "rate" => 0.5,
        }
      end

      let(:orderbook) do
        [
          nil,
          [
            [22_847_510_020, 5010, -0.90403],
            [22_847_510_020, 5005, -0.73563],
            [22_847_510_020, 4990, 0.20603],
            [22_847_510_020, 4985, 0.09944],
          ]
        ]
      end

      it "creates a sell order and take it with a buy order on the target" do
        expect(target.account).to receive(:create_order).with(::Arke::Order.new("BTCUSD", 4999.5, 10, :sell, "limit")).ordered
        expect(target.account).to receive(:create_order).with(::Arke::Order.new("BTCUSD", 4999.5, 10, :buy, "limit")).ordered
        strategy.instance_variable_set(:@expiration, Time.now.to_i - 10)

        EM.synchrony do
          strategy.on_trade(source.id, public_trade)
          EM::Synchrony.add_timer(0.011) { EM.stop }
        end
      end

      it "doesn't create order if the fx rate is not ready" do
        expect(target.account).to_not receive(:create_order)
        strategy.instance_variable_set(:@expiration, Time.now.to_i - 10)
        strategy.fx.instance_variable_set(:@rate, nil)

        EM.synchrony do
          strategy.on_trade(source.id, public_trade)
          EM::Synchrony.add_timer(0.011) { EM.stop }
        end
      end
    end
  end
end
