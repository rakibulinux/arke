# frozen_string_literal: true

describe Arke::Strategy::CandleSampling do
  let(:reactor) { double(:reactor) }
  let(:strategy) { Arke::Strategy::CandleSampling.new([source], target, config, reactor) }
  let(:account) { Arke::Exchange.create(account_config) }
  let(:target_mode) { Arke::Helpers::Flags::DEFAULT_TARGET_FLAGS }
  let(:source_mode) { Arke::Helpers::Flags::DEFAULT_SOURCE_FLAGS }
  let(:source) { Arke::Market.new(config["sources"].first["market_id"], account, Arke::Helpers::Flags::DEFAULT_SOURCE_FLAGS) }
  let(:target) { Arke::Market.new(config["target"]["market_id"], account, target_mode) }
  let(:period) { 15 }
  let(:period_random) { 5 }
  let(:sampling_ratio) { 10_000 }
  let(:max_slippage) { 0.01 }

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
      "type"                => "candle-sampling",
      "period"              => period,
      "period_random_delay" => period_random,
      "fx"                  => fx_config,
      "params"              => {
        "sampling_ratio" => sampling_ratio,
        "max_slippage"   => max_slippage,
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

  # Asks
  let(:sell_side) do
    ::RBTree[
      1000.0, 0.1,
      1000.5, 0.1,
      1002.0, 0.1,
      1010.0, 0.1,
      1011.0, 0.1,
      1015.0, 0.1,
      1021.0, 0.1,
    ]
  end

  # Bids
  let(:buy_side) do
    ::RBTree[
      999.0, 0.1,
      998.0, 0.1,
      997.0, 0.1,
      996.0, 0.1,
      997.0, 0.1,
      995.5, 0.1,
      994.0, 0.1,
    ]
  end

  let(:orderbook) { Arke::Orderbook::Orderbook.new("BTCUSD", sell: sell_side, buy: buy_side) }

  before(:each) do
    target.account.fetch_balances
    allow(target).to receive(:realtime_orderbook).and_return(orderbook)
  end

  context "randomize the sampling ratio" do
    let(:sampling_ratio) { 10_000 }

    it do
      expect(strategy.instance_variable_get(:@next_threashold)).to be_between(9000, 11_000)
    end
  end

  context "trigger buy trade without price slippage" do
    let(:public_trade) { ::Arke::PublicTrade.new(42, "XBTUSDT", "kraken", "buy", 0.1, 1000, 100.0) }

    it "creates a sell order and take it with a buy order on the target" do
      expect(target.account).to receive(:create_order).with(::Arke::Order.new("BTCUSD", 0, 0.1, :buy, "market")).ordered

      EM.synchrony do
        strategy.instance_variable_set(:@next_threashold, 1)
        strategy.on_trade(public_trade)
        EM::Synchrony.add_timer(0.011) { EM.stop }
      end
    end
  end

  context "trigger sell trade without price slippage" do
    let(:public_trade) { ::Arke::PublicTrade.new(42, "XBTUSDT", "kraken", "sell", 0.1, 1000, 100.0) }

    it "creates a sell order and take it with a sell order on the target" do
      expect(target.account).to receive(:create_order).with(::Arke::Order.new("BTCUSD", 0, 0.1, :sell, "market")).ordered

      EM.synchrony do
        strategy.instance_variable_set(:@next_threashold, 1)
        strategy.on_trade(public_trade)
        EM::Synchrony.add_timer(0.011) { EM.stop }
      end
    end
  end

  context "trigger buy trade with price slippage protection" do
    let(:max_slippage) { 0.001 }
    let(:public_trade) { ::Arke::PublicTrade.new(42, "XBTUSDT", "kraken", "buy", 0.3, 1000, 100.0) }

    it "creates a sell order and take it with a buy order on the target" do
      expect(target.account).to receive(:create_order).with(::Arke::Order.new("BTCUSD", 0, 0.2, :buy, "market")).ordered

      EM.synchrony do
        strategy.instance_variable_set(:@next_threashold, 1)
        strategy.on_trade(public_trade)
        EM::Synchrony.add_timer(0.011) { EM.stop }
      end
    end
  end

  context "trigger sell trade with price slippage protection" do
    let(:max_slippage) { 0.001 }
    let(:public_trade) { ::Arke::PublicTrade.new(42, "XBTUSDT", "kraken", "sell", 0.3, 1000, 100.0) }

    it "creates a sell order and take it with a sell order on the target" do
      expect(target.account).to receive(:create_order).with(::Arke::Order.new("BTCUSD", 0, 0.1, :sell, "market")).ordered

      EM.synchrony do
        strategy.instance_variable_set(:@next_threashold, 1)
        strategy.on_trade(public_trade)
        EM::Synchrony.add_timer(0.011) { EM.stop }
      end
    end
  end


end
