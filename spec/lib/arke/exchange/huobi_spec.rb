describe Arke::Exchange::Huobi do
  include_context 'mocked huobi'

  before(:all) { Arke::Log.define }

  let(:faraday_adapter) { :em_synchrony }
  let(:huobi) do
    Arke::Exchange::Huobi.new(
      {
        'host' => 'api.huobi.pro',
        'key' => 'Uwg8wqlxueiLCsbTXjlogviL8hdd60',
        'secret' => 'OwpadzSYOSkzweoJkjPrFeVgjOwOuxVHk8FXIlffdWw',
        :faraday_adapter => faraday_adapter,
      }
    )
  end
  let(:config) do
    {
      'market' => {
        "id" => "ETHUSDT",
        "base" => "ETH",
        "quote" => "USDT",
      }
    }
  end
  before { huobi.configure_market(config["market"]) }

  context 'ojbect initialization' do
    it 'is a sublass of Arke::Exchange::Base' do
      expect(Arke::Exchange::Huobi.superclass).to eq(Arke::Exchange::Base)
    end

    it 'has an orderbook' do
      expect(huobi.orderbook).to be_an_instance_of(Arke::Orderbook::Orderbook)
    end
  end

  context 'getting snapshot' do
    let(:snapshot_buy_order_1) { Arke::Order.new('ETHUSDT', 135.84000000, 6.62227000, :buy) }
    let(:snapshot_buy_order_2) { Arke::Order.new('ETHUSDT', 135.85000000, 0.57176000, :buy) }
    let(:snapshot_buy_order_3) { Arke::Order.new('ETHUSDT', 135.87000000, 36.43875000, :buy) }

    let(:snapshot_sell_order_1) { Arke::Order.new('ETHUSDT', 135.91000000, 0.00070000, :sell) }
    let(:snapshot_sell_order_2) { Arke::Order.new('ETHUSDT', 135.93000000, 8.00000000, :sell) }
    let(:snapshot_sell_order_3) { Arke::Order.new('ETHUSDT', 135.95000000, 1.11699000, :sell) }

    context "using default adapter" do
      let(:faraday_adapter) { Faraday.default_adapter }

      it 'gets a snapshot' do
        huobi.update_orderbook
        expect(huobi.orderbook.book[:buy].empty?).to be false
        expect(huobi.orderbook.book[:sell].empty?).to be false
      end

      it 'gets filled with buy orders from snapshot' do
        huobi.update_orderbook
        expect(huobi.orderbook.contains?(snapshot_buy_order_1)).to eq(true)
        expect(huobi.orderbook.contains?(snapshot_buy_order_2)).to eq(true)
        expect(huobi.orderbook.contains?(snapshot_buy_order_3)).to eq(true)
      end

      it 'gets filled with sell orders from snapshot' do
        huobi.update_orderbook
        expect(huobi.orderbook.contains?(snapshot_sell_order_1)).to eq(true)
        expect(huobi.orderbook.contains?(snapshot_sell_order_2)).to eq(true)
        expect(huobi.orderbook.contains?(snapshot_sell_order_3)).to eq(true)
      end
    end

    context "using EM Synchrony adapter" do
      it 'gets a snapshot' do
        EM.synchrony do
          huobi.update_orderbook
          expect(huobi.orderbook.book[:buy].empty?).to be false
          expect(huobi.orderbook.book[:sell].empty?).to be false
          EM.stop
        end
      end

      it 'gets filled with buy orders from snapshot' do
        huobi.update_orderbook
        expect(huobi.orderbook.contains?(snapshot_buy_order_1)).to eq(true)
        expect(huobi.orderbook.contains?(snapshot_buy_order_2)).to eq(true)
        expect(huobi.orderbook.contains?(snapshot_buy_order_3)).to eq(true)
      end

      it 'gets filled with sell orders from snapshot' do
        huobi.update_orderbook
        expect(huobi.orderbook.contains?(snapshot_sell_order_1)).to eq(true)
        expect(huobi.orderbook.contains?(snapshot_sell_order_2)).to eq(true)
        expect(huobi.orderbook.contains?(snapshot_sell_order_3)).to eq(true)
      end
    end
  end

  context "get_balances" do
    it "fetchs the account balance in arke format" do
      expect(huobi.get_balances).to eq([
        {
          "currency" => "USDT",
          "total" => 155.0,
          "free" => 123.0,
          "locked" => 32.0,
        },
        {
          "currency" => "ETH",
          "total" => 499999894616.1302471000,
          "free" => 499999894616.1302471000,
          "locked" => 0.0,
        }
      ])
    end
  end

  context "fetch_openorders" do
    it "fetchs the account openorders and stores them into local openorder cache" do
      huobi.fetch_openorders
      expect(huobi.open_orders[:buy].size).to eq(1)
      expect(huobi.open_orders[:sell].size).to eq(1)
      expect(huobi.open_orders[:buy][0.452]).to eq({43 => Arke::Order.new("ETHUSDT", 0.452, 0.3, :buy)})
      expect(huobi.open_orders[:sell][0.453]).to eq({42 => Arke::Order.new("ETHUSDT", 0.453, 1.0, :sell)})
    end
  end

  context 'order_create' do
    let(:order) { Arke::Order.new('ETHUSDT', 250, 1, :buy) }

    it 'creates an order on Huobi' do
      expect{huobi.create_order(order)}.to_not raise_error(Exception)
    end
  end
end
