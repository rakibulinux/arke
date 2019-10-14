# frozen_string_literal: true

describe Arke::Exchange::Binance do
  include_context "mocked binance"

  let(:market_config) do
    {
      "id"             => "ETHUSDT",
      "base"           => "ETH",
      "quote"          => "USDT",
      "min_ask_amount" => 0.01,
      "min_bid_amount" => 0.01,
    }
  end

  let(:binance) do
    Arke::Exchange::Binance.new(
      "host"   => "api.binance.com",
      "key"    => "Uwg8wqlxueiLCsbTXjlogviL8hdd60",
      "secret" => "OwpadzSYOSkzweoJkjPrFeVgjOwOuxVHk8FXIlffdWw"
    )
  end

  let!(:market) { Arke::Market.new(market_config, binance) }

  context "ojbect initialization" do
    it "is a sublass of Arke::Exchange::Base" do
      expect(Arke::Exchange::Binance.superclass).to eq(Arke::Exchange::Base)
    end

    it "has an orderbook" do
      expect(market.orderbook).to be_an_instance_of(Arke::Orderbook::Orderbook)
    end
  end

  context "getting snapshot" do
    let(:snapshot_buy_order_1) { Arke::Order.new("ETHUSDT", 135.84000000, 6.62227000, :buy) }
    let(:snapshot_buy_order_2) { Arke::Order.new("ETHUSDT", 135.85000000, 0.57176000, :buy) }
    let(:snapshot_buy_order_3) { Arke::Order.new("ETHUSDT", 135.87000000, 36.43875000, :buy) }

    let(:snapshot_sell_order_1) { Arke::Order.new("ETHUSDT", 135.91000000, 0.00070000, :sell) }
    let(:snapshot_sell_order_2) { Arke::Order.new("ETHUSDT", 135.93000000, 8.00000000, :sell) }
    let(:snapshot_sell_order_3) { Arke::Order.new("ETHUSDT", 135.95000000, 1.11699000, :sell) }

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

  context "get_balances" do
    it "fetchs the account balance in arke format" do
      expect(binance.get_balances).to eq(
        [
          {
            "currency" => "BTC",
            "total"    => 4_723_846.89208129,
            "free"     => 4_723_846.89208129,
            "locked"   => 0.0,
          },
          {
            "currency" => "LTC",
            "total"    => 4_763_468.68006011,
            "free"     => 4_763_368.68006011,
            "locked"   => 100.0,
          }
        ]
      )
    end
  end

  context "fetch_openorders" do
    it "fetchs the account openorders and stores them into local openorder cache" do
      market.fetch_openorders
      expect(market.open_orders[:buy].size).to eq(1)
      expect(market.open_orders[:sell].size).to eq(0)
      expect(market.open_orders[:buy][0.1]).to eq(42 => Arke::Order.new("LTCBTC", 0.1, 0.9, :buy))
    end
  end

  context "order_create" do
    let(:order) { Arke::Order.new("ETHUSDT", 250, 1, :buy) }
    let(:incorrect_order) { Arke::Order.new("ETHUSDT", 1, 1, :buy) }
    let(:small_order) { Arke::Order.new("ETHUSDT", 5, 1, :buy) }
    let(:timestamp) { "1551720218" }
    let(:query) do
      "price=#{order.price.to_f}&quantity=#{order.amount.to_f}&recvWindow=5000&" \
      "side=#{order.side.upcase}&symbol=#{order.market}&timeInForce=GTC&timestamp=#{timestamp}&type=LIMIT"
    end

    let(:query_hash) do
      {
        symbol:      order.market,
        side:        order.side.upcase,
        type:        "LIMIT",
        timeInForce: "GTC",
        quantity:    order.amount.to_f,
        price:       order.price.to_f,
        recvWindow:  "5000",
        timestamp:   timestamp
      }
    end

    it "creates an order on Binance" do
      expect { binance.create_order(order) }.to_not raise_error(Exception)
    end

    it "creates an order on Binance" do
      expect { binance.create_order(small_order) }.to_not raise_error(Exception)
    end

    it "incorrect order on Binance" do
      expect { binance.create_order(incorrect_order) }.to raise_error(Exception)
    end
  end

  context "get_amount" do
    let(:order) { Arke::Order.new("ETHUSDT", 250, 1, :buy) }
    let(:danger_order) { Arke::Order.new("ETHUSDT", 3, 3, :buy) }
    let(:small_order) { Arke::Order.new("ETHUSDT", 1, 1, :buy) }

    it "get min_notional" do
      expect(binance.get_min_notional("ETHUSDT")).to eq 10
    end

    it "for normal order" do
      expect(binance.get_amount(order)).to eq 1
    end

    it "where order notional more than 20% from min_notional" do
      expect(binance.get_amount(danger_order)).to eq 3.33334
    end

    it "amount of order too small" do
      expect { binance.get_amount(small_order) }.to raise_error(Exception)
    end
  end
end
