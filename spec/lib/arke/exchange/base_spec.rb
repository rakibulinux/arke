describe Arke::Exchange::Binance do
  let(:faraday_adapter) { :em_synchrony }
  let(:base) do
    Arke::Exchange::Base.new({ "driver" => "base" })
  end

  let(:market_config) do {
    "market" => {
      "id" => "ETHUSDt",
      "base" => "ETH",
      "quote" => "USDT",
      },
    }
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

  context "notify_trade" do
    let(:trade) { Arke::Trade.new("ethusdt", :sell, 0.1, 180.0132, 632478) }
    let(:incorrect_trade) { Arke::Trade.new("btcusdt", :sell, 0.1, 180.0132, 632479) }
    let(:order) { Arke::Order.new("ETHUSDT", 2, 1, :buy) }
    let(:strategy) { double(:strategy) }

    it "notifies trade when the market id match" do
      strategy.stub(:orderback)
      base.register_on_trade_cb(&strategy.method(:orderback))
      expect(strategy).to receive(:orderback).once.with(trade)
      base.notify_trade(trade)
    end

    it "doesn't notify then the market doesn't match" do
      strategy.stub(:orderback)
      base.register_on_trade_cb(&strategy.method(:orderback))
      expect(strategy).not_to receive(:orderback).with(trade, order)
      base.notify_trade(incorrect_trade)
    end
  end
end
