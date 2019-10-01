# frozen_string_literal: true

describe Arke::Exchange::Luno do
  include_context "mocked luno"
  let(:luno) do
    Arke::Exchange::Luno.new(
      "key"    => "abcdefghijklm",
      "secret" => "skhfksjhgksdjhfksjdfkjsdfksjhdkfsj"
    )
  end
  let(:market_config) do
    {
      "id"    => "XBTZAR",
      "base"  => "XBT",
      "quote" => "ZAR",
    }
  end
  let!(:market) { Arke::Market.new(market_config, luno) }

  context "get_balances" do
    it "fetchs the account balance in arke format" do
      expect(luno.get_balances).to eq(
        [
          {
            "currency" => "XBT",
            "total"    => 100.0,
            "free"     => 90.0,
            "locked"   => 10.0,
          }
        ]
      )
    end
  end

  context "update_orderbook" do
    let(:snapshot_buy_order_1) { Arke::Order.new("XBTZAR", 1100.00, 0.10, :buy) }
    let(:snapshot_buy_order_2) { Arke::Order.new("XBTZAR", 1000.00, 0.10, :buy) }
    let(:snapshot_buy_order_3) { Arke::Order.new("XBTZAR", 900.00, 0.10, :buy) }

    let(:snapshot_sell_order_1) { Arke::Order.new("XBTZAR", 1180.00, 0.10, :sell) }
    let(:snapshot_sell_order_2) { Arke::Order.new("XBTZAR", 2000.00, 0.10, :sell) }

    it "fetchs orderbook" do
      market.update_orderbook
      expect(market.orderbook.book[:buy].empty?).to be false
      expect(market.orderbook.book[:sell].empty?).to be false
    end

    it "gets filled with buy orders from snapshot" do
      market.update_orderbook
      expect(market.orderbook.contains?(snapshot_buy_order_1)).to eq(true)
      expect(market.orderbook.contains?(snapshot_buy_order_2)).to eq(true)
      expect(market.orderbook.contains?(snapshot_buy_order_3)).to eq(true)
    end

    it "gets filled with sell orders from snapshot" do
      market.update_orderbook
      expect(market.orderbook.contains?(snapshot_sell_order_1)).to eq(true)
      expect(market.orderbook.contains?(snapshot_sell_order_2)).to eq(true)
    end
  end

  context "markets" do
    it "gets all markets from platform" do
      expect(luno.markets).to contain_exactly("XBTZMW", "ETHXBT", "XBTEUR", "XBTIDR", "XBTMYR", "XBTNGN", "XBTZAR")
    end
  end

  context "create_order" do
    let(:order) { Arke::Order.new("XBTZAR", 1180.00, 0.10, :sell) }

    it "creates order" do
      expect { luno.create_order(order) }.to_not raise_error(Exception)
    end
  end
end
