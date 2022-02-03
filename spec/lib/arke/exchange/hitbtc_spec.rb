# frozen_string_literal: true

describe Arke::Exchange::Hitbtc do
  include_context "mocked hitbtc"
  let(:hitbtc) do
    Arke::Exchange::Hitbtc.new(
      "host"   => "api.hitbtc.com",
      "key"    => "abcdefghijklm",
      "secret" => "skhfksjhgksdjhfksjdfkjsdfksjhdkfsj"
    )
  end
  let(:market_id) { "ETHUSD" }
  let!(:market) { Arke::Market.new(market_id, hitbtc) }

  context "get_balances" do
    it "fetchs the account balance in arke format" do
      expect(hitbtc.get_balances).to eq(
        [
          {
            "currency" => "ETH",
            "total"    => 10.56,
            "free"     => 10.0,
            "locked"   => 0.56,
          },
          {
            "currency" => "USD",
            "total"    => 0.010205869,
            "free"     => 0.010205869,
            "locked"   => 0.0,
          }
        ]
      )
    end
  end

  context "update_orderbook" do
    let(:snapshot_buy_order_1) { Arke::Order.new("ETHUSD", 0.046001, 0.005, :buy) }
    let(:snapshot_buy_order_2) { Arke::Order.new("ETHUSD", 0.046, 0.2, :buy) }

    let(:snapshot_sell_order_1) { Arke::Order.new("ETHUSD", 0.046002, 0.088, :sell) }
    let(:snapshot_sell_order_2) { Arke::Order.new("ETHUSD", 0.046800, 0.2, :sell) }

    it "fetchs orderbook" do
      market.update_orderbook
      expect(market.orderbook.book[:buy].empty?).to be false
      expect(market.orderbook.book[:sell].empty?).to be false
    end

    it "gets filled with buy orders from snapshot" do
      market.update_orderbook
      expect(market.orderbook.contains?(snapshot_buy_order_1)).to eq(true)
      expect(market.orderbook.contains?(snapshot_buy_order_2)).to eq(true)
    end

    it "gets filled with sell orders from snapshot" do
      market.update_orderbook
      expect(market.orderbook.contains?(snapshot_sell_order_1)).to eq(true)
      expect(market.orderbook.contains?(snapshot_sell_order_2)).to eq(true)
    end
  end

  context "markets" do
    it "gets all markets from platform" do
      expect(hitbtc.markets).to contain_exactly("ETHBTC", "ETHUSD")
    end
  end

  context "market_config" do
    it "returns market config" do
      expect(hitbtc.market_config("ETHBTC")).to eq(
        "id"               => "ETHBTC",
        "base_unit"        => "ETH",
        "quote_unit"       => "BTC",
        "min_price"        => nil,
        "max_price"        => nil,
        "min_amount"       => 0.001,
        "amount_precision" => 3,
        "price_precision"  => 6
      )
    end
  end

  context "create_order" do
    let(:order) { Arke::Order.new("ETHUSD", 1180.00, 0.10, :sell) }

    it "creates order" do
      order.apply_requirements(hitbtc)
      expect { hitbtc.create_order(order) }.to_not raise_error
    end
  end
end
