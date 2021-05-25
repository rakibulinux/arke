# frozen_string_literal: true

describe Arke::Strategy::Arbitrage do
  let!(:strategy) { Arke::Strategy::Arbitrage.new([source1, source2], nil, strategy_config, nil) }
  let(:account1) { Arke::Exchange.create(account1_config) }
  let(:account2) { Arke::Exchange.create(account2_config) }
  let(:source1) {
    Arke::Market.new(strategy_config["sources"][0]["market_id"], account1, Arke::Helpers::Flags::DEFAULT_SOURCE_FLAGS)
  }
  let(:source2) {
    Arke::Market.new(strategy_config["sources"][1]["market_id"], account2, Arke::Helpers::Flags::DEFAULT_SOURCE_FLAGS)
  }
  let(:profit) { 1.0 }
  let(:min_amount) { 1.5 }
  let(:dry_run) { false }
  let(:max_amount_perc) { 0.05 }
  let(:strategy_config) do
    {
      "type"    => "arbitrage",
      "id"      => "arbitrage-BTCUSD",
      "params"  => {
        "profit"          => profit,
        "min_amount"      => min_amount,
        "dry_run"         => dry_run,
        "max_amount_perc" => max_amount_perc,
      },
      "sources" => [
        market1,
        market2
      ],
    }
  end

  let(:account1_config) do
    {
      "id"        => 1,
      "driver"    => "bitfaker",
      "orderbook" => orderbook1,
      "taker_fee" => taker_fee1,
      "params"    => {
        "balances" => balances1
      }
    }
  end

  let(:taker_fee1) { 0.001 }
  let(:taker_fee2) { 0.001 }

  let(:account2_config) do
    {
      "id"        => 2,
      "driver"    => "bitfaker",
      "orderbook" => orderbook2,
      "taker_fee" => taker_fee2,
      "params"    => {
        "balances" => balances2
      }
    }
  end

  let(:balances1) do
    [
      {
        "currency" => "BTC",
        "total"    => 3,
        "free"     => 3,
        "locked"   => 0
      },
      {
        "currency" => "USD",
        "total"    => 10_000,
        "free"     => 10_000,
        "locked"   => 0,
      }
    ]
  end

  let(:balances2) do
    [
      {
        "currency" => "btc",
        "total"    => 3,
        "free"     => 3,
        "locked"   => 0
      },
      {
        "currency" => "usd",
        "total"    => 10_000,
        "free"     => 10_000,
        "locked"   => 0,
      }
    ]
  end

  let(:market1) do
    {
      "account_id" => 1,
      "market_id"  => "BTCUSD",
    }
  end

  let(:market2) do
    {
      "account_id" => 2,
      "market_id"  => "btcusd",
    }
  end

  before(:each) do
    [source1, source2].each do |src|
      src.start
      src.update_orderbook
      src.account.executor = double(:executor)
    end
  end

  context "simple arbitrage opportunity" do
    let(:orderbook1) do
      [nil, [
        # Asks
        [nil, 110.987, -251],
        [nil, 110.986, -239],
        # Bids
        [nil, 110.984, 20],
        [nil, 110.983, 1],
      ]]
    end

    let(:orderbook2) do
      [nil, [
        # Asks
        [nil, 99.987, -251],
        [nil, 99.986, -239],
        [nil, 99.985, -23],
        # Bids
        [nil, 99.984, 20],
        [nil, 99.983, 1],
        [nil, 99.982, 1],
        [nil, 99.981, 1],
      ]]
    end

    it do
      expect(source1.account.executor).to receive(:push).with("arbitrage-BTCUSD", [
        ::Arke::Action.new(:order_create, source1, order: ::Arke::Order.new("BTCUSD", "110.984".to_d, "3".to_d, :sell, "limit"))
      ])

      expect(source2.account.executor).to receive(:push).with("arbitrage-BTCUSD", [
        ::Arke::Action.new(:order_create, source2, order: ::Arke::Order.new("btcusd", "99.985".to_d, "3".to_d, :buy, "limit"))
      ])

      EM.synchrony do
        strategy.call
        EM.stop
      end
    end
  end

  context "no arbitrage opportunity" do
    let(:orderbook1) do
      [nil, [
        # Asks
        [nil, 99.987000, -251],
        [nil, 99.986000, -239],
        [nil, 99.985000, -23],
        # Bids
        [nil, 99.984000, 20],
        [nil, 99.983000, 1],
        [nil, 99.982000, 1],
        [nil, 99.981000, 1],
      ]]
    end

    let(:orderbook2) do
      [nil, [
        # Asks
        [nil, 99.987000, -251],
        [nil, 99.986000, -239],
        [nil, 99.985000, -23],
        # Bids
        [nil, 99.984000, 20],
        [nil, 99.983000, 1],
        [nil, 99.982000, 1],
        [nil, 99.981000, 1],
      ]]
    end

    it do
      strategy.call
    end
  end

  # context "amount capped by the bid (in base) WITHOUT reaching the min order amount" do
  # end

  # context "amount capped by the bid (in base) WITH reaching the min order amount" do
  # end

  # context "amount capped by the ask (in quote) WITHOUT reaching the min order amount" do
  # end

  # context "amount capped by the ask (in quote) WITH reaching the min order amount" do
  # end
end
