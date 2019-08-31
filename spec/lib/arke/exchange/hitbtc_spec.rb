describe Arke::Exchange::Hitbtc do
  include_context "mocked hitbtc"
  let(:hitbtc) do
    Arke::Exchange::Hitbtc.new(
      {
        "host" => "api.hitbtc.com",
        "key" => "abcdefghijklm",
        "secret" => "skhfksjhgksdjhfksjdfkjsdfksjhdkfsj",
      }
    )
  end
  let(:config) do
    {
      "market" => {
        "id" => "ETHUSD",
        "base" => "ETH",
        "quote" => "USD",
      }
    }
  end
  before { hitbtc.configure_market(config["market"]) }

  context "get_balances" do
    it "fetchs the account balance in arke format" do
      expect(hitbtc.get_balances).to eq([
        {
          "currency" => "ETH",
          "total" => 10.56,
          "free" => 10.0,
          "locked" => 0.56,
        },
        {
          "currency" => "USD",
          "total" => 0.010205869,
          "free" => 0.010205869,
          "locked" => 0.0,
        }
      ])
    end
  end

  context "update_orderbook" do
    let(:snapshot_buy_order_1) { Arke::Order.new('ETHUSD', 0.046001, 0.005, :buy) }
    let(:snapshot_buy_order_2) { Arke::Order.new('ETHUSD', 0.046, 0.2, :buy) }

    let(:snapshot_sell_order_1) { Arke::Order.new('ETHUSD', 0.046002, 0.088, :sell) }
    let(:snapshot_sell_order_2) { Arke::Order.new('ETHUSD', 0.046800, 0.2, :sell) }

    it "fetchs orderbook" do
      hitbtc.update_orderbook
      expect(hitbtc.orderbook.book[:buy].empty?).to be false
      expect(hitbtc.orderbook.book[:sell].empty?).to be false
    end

    it 'gets filled with buy orders from snapshot' do
      hitbtc.update_orderbook
      expect(hitbtc.orderbook.contains?(snapshot_buy_order_1)).to eq(true)
      expect(hitbtc.orderbook.contains?(snapshot_buy_order_2)).to eq(true)
    end

    it 'gets filled with sell orders from snapshot' do
      hitbtc.update_orderbook
      expect(hitbtc.orderbook.contains?(snapshot_sell_order_1)).to eq(true)
      expect(hitbtc.orderbook.contains?(snapshot_sell_order_2)).to eq(true)
    end
  end

  context "markets" do

    it "gets all markets from platform" do
      expect(hitbtc.markets).to contain_exactly("ETHBTC", "ETHUSD")
    end
  end

  context "create_order" do
    let(:order) { Arke::Order.new('ETHUSD', 1180.00, 0.10, :sell) }

    it "creates order" do
      expect{hitbtc.create_order(order)}.to_not raise_error(Exception)
    end
  end
end
