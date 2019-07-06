describe Arke::Exchange::Binance do
  let(:faraday_adapter) { :em_synchrony }
  let(:base) do
    Arke::Exchange::Base.new(
      {
        "driver" => "base",
        "market" => "ETHUSDT",
      }
    )
  end

  let(:balance_btc) do
    {
      "currency" => "BTC",
      "balance" => 4723846.89208129,
      "locked" => 0.0,
    }
  end

  let(:balance_ltc) do
    {
      "currency" => "LTC",
      "balance" => 4763468.68006011,
      "locked" => 100.0,
    }
  end

  let(:balances) do
    [
      balance_btc,
      balance_ltc,
    ]
  end

  context "getting balance" do
    before(:each) do
      base.instance_variable_set(:@balances, balances)
    end

    it "returns the balance info of the currency "do
      expect(base.balances).to eq(balances)
      expect(base.balance("BTC")).to eq(balance_btc)
      expect(base.balance("LTC")).to eq(balance_ltc)
      expect(base.balance("USD")).to eq(nil)
    end
  end

  context "build_query" do
    it "sorts params and builds a query string" do
      expect(base.build_query(b: 12, a: 21)).to eq("a=21&b=12")
    end
  end
end
