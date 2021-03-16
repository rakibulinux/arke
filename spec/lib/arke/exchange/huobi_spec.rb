# frozen_string_literal: true

describe Arke::Exchange::Huobi do
  include_context "mocked huobi"

  before(:all) { Arke::Log.define }

  let(:faraday_adapter) { :em_synchrony }
  let(:huobi) do
    Arke::Exchange::Huobi.new(
      "host"           => "api.huobi.pro",
      "key"            => "Uwg8wqlxueiLCsbTXjlogviL8hdd60",
      "secret"         => "OwpadzSYOSkzweoJkjPrFeVgjOwOuxVHk8FXIlffdWw",
      :faraday_adapter => faraday_adapter,
      "ts_pattern"     => "%Y-%m-%dT%H"
    )
  end
  let(:market_id) { "ethusdt" }
  let!(:market) { Arke::Market.new(market_id, huobi) }

  context "ojbect initialization" do
    it "is a sublass of Arke::Exchange::Base" do
      expect(Arke::Exchange::Huobi.superclass).to eq(Arke::Exchange::Base)
    end

    it "has an orderbook" do
      expect(market.orderbook).to be_an_instance_of(Arke::Orderbook::Orderbook)
    end
  end

  context "getting snapshot" do
    let(:snapshot_buy_order_1) { Arke::Order.new("ethusdt", 135.84000000, 6.62227000, :buy) }
    let(:snapshot_buy_order_2) { Arke::Order.new("ethusdt", 135.85000000, 0.57176000, :buy) }
    let(:snapshot_buy_order_3) { Arke::Order.new("ethusdt", 135.87000000, 36.43875000, :buy) }

    let(:snapshot_sell_order_1) { Arke::Order.new("ethusdt", 135.91000000, 0.00070000, :sell) }
    let(:snapshot_sell_order_2) { Arke::Order.new("ethusdt", 135.93000000, 8.00000000, :sell) }
    let(:snapshot_sell_order_3) { Arke::Order.new("ethusdt", 135.95000000, 1.11699000, :sell) }

    context "using default adapter" do
      let(:faraday_adapter) { Faraday.default_adapter }

      it "gets a snapshot" do
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
        expect(market.orderbook.contains?(snapshot_sell_order_3)).to eq(true)
      end
    end

    context "using EM Synchrony adapter" do
      it "gets a snapshot" do
        EM.synchrony do
          market.update_orderbook
          expect(market.orderbook.book[:buy].empty?).to be false
          expect(market.orderbook.book[:sell].empty?).to be false
          EM.stop
        end
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
        expect(market.orderbook.contains?(snapshot_sell_order_3)).to eq(true)
      end
    end
  end

  context "market_config" do
    it "returns market config" do
      expect(huobi.market_config("btcusdt")).to eq(
        "id"               => "btcusdt",
        "base_unit"        => "btc",
        "quote_unit"       => "usdt",
        "min_price"        => nil,
        "max_price"        => nil,
        "min_amount"       => 0.0001,
        "max_amount"       => 1000,
        "amount_precision" => 6,
        "price_precision"  => 2,
        "min_order_size"   => 1
      )
    end
  end

  context "get_balances" do
    it "fetchs the account balance in arke format" do
      expect(huobi.get_balances).to eq(
        [
          {
            "currency" => "USDT",
            "total"    => 155.0,
            "free"     => 123.0,
            "locked"   => 32.0,
          },
          {
            "currency" => "ETH",
            "total"    => 499_999_894_616.1302471000,
            "free"     => 499_999_894_616.1302471000,
            "locked"   => 0.0,
          }
        ]
      )
    end
  end

  context "fetch_openorders" do
    it "fetchs the account openorders and stores them into local openorder cache" do
      market.fetch_openorders
      expect(market.open_orders[:buy].size).to eq(1)
      expect(market.open_orders[:sell].size).to eq(1)
      expect(market.open_orders[:buy][0.452]).to eq(43 => Arke::Order.new("ethusdt", 0.452, 0.3, :buy))
      expect(market.open_orders[:sell][0.453]).to eq(42 => Arke::Order.new("ethusdt", 0.453, 1.0, :sell))
    end
  end

  context "order_create" do
    let(:order) { Arke::Order.new("ethusdt", 250, 1, :buy) }

    it "creates an order on Huobi" do
      order.apply_requirements(huobi)
      expect { huobi.create_order(order) }.to_not raise_error(Exception)
    end
  end

  context "public trade event received on websocket" do
    let(:trade_event) do
      OpenStruct.new(
        "type": "message",
        "data": [31, 139, 8, 0, 0, 0, 0, 0, 0, 0, 165, 208, 75, 142, 194, 48, 12, 6, 224, 187, 120, 93, 69, 142, 243, 116, 110, 48, 103, 64, 179, 136, 154, 72, 68, 20, 24, 181, 97, 133, 122, 247, 9, 108, 10, 243, 144, 130, 216, 218, 254, 245, 217, 190, 194, 184, 135, 0, 199, 56, 31, 114, 21, 185, 238, 47, 75, 170, 162, 206, 49, 101, 145, 114, 141, 101, 130, 1, 234, 2, 65, 26, 79, 90, 51, 75, 101, 172, 106, 165, 50, 30, 32, 92, 161, 164, 214, 66, 101, 53, 106, 135, 222, 248, 159, 195, 218, 209, 0, 41, 214, 8, 97, 247, 123, 218, 33, 179, 67, 139, 82, 254, 29, 188, 239, 241, 113, 15, 73, 70, 178, 198, 41, 212, 3, 196, 227, 249, 114, 170, 16, 140, 48, 10, 219, 50, 95, 115, 25, 51, 4, 114, 36, 188, 109, 92, 153, 243, 88, 203, 249, 212, 14, 91, 242, 52, 193, 58, 252, 71, 27, 231, 165, 235, 166, 213, 70, 163, 144, 172, 221, 59, 180, 149, 154, 250, 105, 122, 164, 91, 153, 158, 105, 255, 26, 173, 180, 53, 221, 180, 220, 104, 18, 248, 236, 242, 107, 46, 241, 237, 73, 157, 46, 110, 174, 22, 228, 204, 91, 50, 122, 143, 157, 50, 49, 111, 178, 20, 236, 209, 119, 208, 159, 235, 250, 13, 19, 209, 21, 214, 76, 3, 0, 0]
      )
    end

    it "notifies public trade to registered callbacks" do
      callback = double(:callback)
      expect(callback).to receive(:call).with(Arke::PublicTrade.new(101_902_657_304, "ethusdt", "huobi", :sell, 5.5303.to_d, 272.86.to_d, 5.5303.to_d * 272.86.to_d, 1_582_449_913_472))
      expect(callback).to receive(:call).with(Arke::PublicTrade.new(101_902_657_303, "ethusdt", "huobi", :sell, 0.1947.to_d, 272.86.to_d, 0.1947.to_d * 272.86.to_d, 1_582_449_913_472))
      expect(callback).to receive(:call).with(Arke::PublicTrade.new(101_902_657_302, "ethusdt", "huobi", :sell, 0.0192.to_d, 272.88.to_d, 0.0192.to_d * 272.88.to_d, 1_582_449_913_472))
      expect(callback).to receive(:call).with(Arke::PublicTrade.new(101_902_657_301, "ethusdt", "huobi", :sell, 2.0.to_d, 272.89.to_d, 2.0.to_d * 272.89.to_d, 1_582_449_913_472))
      expect(callback).to receive(:call).with(Arke::PublicTrade.new(101_902_657_300, "ethusdt", "huobi", :sell, 4.275.to_d, 272.89.to_d, 4.275.to_d * 272.89.to_d, 1_582_449_913_472))
      expect(callback).to receive(:call).with(Arke::PublicTrade.new(101_902_657_299, "ethusdt", "huobi", :sell, 1.9808.to_d, 272.89.to_d, 1.9808.to_d * 272.89.to_d, 1_582_449_913_472))
      huobi.register_on_public_trade_cb(&callback.method(:call))
      huobi.ws_read_message(:public, trade_event)
    end
  end

  context "empty message received on websocket" do
    let(:trade_event) do
      require "zlib"
      io = StringIO.new
      gz = Zlib::GzipWriter.new(io)
      gz.write "{}"
      gz.close
      OpenStruct.new(
        "type": "message",
        "data": io.string.each_byte.to_a
      )
    end

    it "doesn't notify about trade for other messages" do
      callback = double(:callback)
      expect(callback).to_not receive(:call)
      huobi.register_on_public_trade_cb(&callback.method(:call))
      huobi.ws_read_message(:public, trade_event)
    end
  end
end
