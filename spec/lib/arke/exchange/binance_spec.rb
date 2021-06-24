# frozen_string_literal: true

describe Arke::Exchange::Binance do
  include_context "mocked binance"

  let(:market_id) { "ETHUSDT" }

  let(:binance) do
    Arke::Exchange::Binance.new(
      "host"   => "https://api.binance.com",
      "key"    => "Uwg8wqlxueiLCsbTXjlogviL8hdd60",
      "secret" => "OwpadzSYOSkzweoJkjPrFeVgjOwOuxVHk8FXIlffdWw"
    )
  end

  let!(:market) { Arke::Market.new(market_id, binance) }

  context "ojbect initialization" do
    it "is a sublass of Arke::Exchange::Base" do
      expect(Arke::Exchange::Binance.superclass).to eq(Arke::Exchange::Base)
    end

    it "has an orderbook" do
      expect(market.orderbook).to be_an_instance_of(Arke::Orderbook::Orderbook)
    end
  end

  context "getting snapshot" do
    let(:snapshot_buy_order_1) { Arke::Order.new("ETHUSDT", 2, 1, :buy) }
    let(:snapshot_sell_order_1) { Arke::Order.new("ETHUSDT", 6, 1, :sell) }

    context "using default adapter" do
      it "gets a snapshot" do
        market.update_orderbook
        expect(market.orderbook.book[:buy].empty?).to be false
        expect(market.orderbook.book[:sell].empty?).to be false
        expect(market.orderbook.contains?(snapshot_buy_order_1)).to eq(true)
        expect(market.orderbook.contains?(snapshot_sell_order_1)).to eq(true)
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
    let(:small_order) { Arke::Order.new("ETHUSDT", 5, 1, :buy) }
    let(:very_small_order) { Arke::Order.new("ETHUSDT", 1, 1, :buy) }
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
      order.apply_requirements(binance)
      expect { binance.create_order(order) }.to_not raise_error(Exception)
    end

    it "creates an order on Binance" do
      small_order.apply_requirements(binance)
      expect { binance.create_order(small_order) }.to_not raise_error(Exception)
    end

    it "incorrect order on Binance" do
      very_small_order.apply_requirements(binance)
      expect { binance.create_order(very_small_order) }.to_not raise_error(Exception)
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
      expect(binance.get_amount(order)).to eq "1.00000"
    end

    it "where order notional more than 20% from min_notional" do
      expect(binance.get_amount(danger_order)).to eq "3.33334"
    end

    it "amount of order too small" do
      expect { binance.get_amount(small_order) }.to_not raise_error(Exception)
    end

    it "amount of market order without price" do
      o = Arke::Order.new("ETHUSDT", nil, 1, :buy)
      expect(binance.get_amount(o)).to eq "1.00000"
    end

  end

  context "receive public trades events on websocket" do
    #
    # The Trade Streams push raw trade information; each trade has a unique buyer and seller.
    #
    # {
    #   "e": "trade",     // Event type
    #   "E": 123456789,   // Event time
    #   "s": "BNBBTC",    // Symbol
    #   "t": 12345,       // Trade ID
    #   "p": "0.001",     // Price
    #   "q": "100",       // Quantity
    #   "b": 88,          // Buyer order ID
    #   "a": 50,          // Seller order ID
    #   "T": 123456785,   // Trade time
    #   "m": true,        // Is the buyer the market maker?
    #   "M": true         // Ignore
    # }

    let(:trade_event) do
      OpenStruct.new(
        "type": "message",
        "data":
                {
                  "stream" => "engbtc@trade",
                  "data"   => {
                    "e" => "trade",
                    "E" => 1_571_640_883_301,
                    "s" => "ENGBTC",
                    "t" => 6_026_899,
                    "p" => "0.00003700",
                    "q" => "1242.00000000",
                    "b" => 61_844_192,
                    "a" => 61_844_772,
                    "T" => 1_571_640_883_296,
                    "m" => true,
                    "M" => true
                  }
                }.to_json
      )
    end

    #
    # The Aggregate Trade Streams push trade information that is aggregated for a single taker order.
    #
    # {
    #   "e": "aggTrade",  // Event type
    #   "E": 123456789,   // Event time
    #   "s": "BNBBTC",    // Symbol
    #   "a": 12345,       // Aggregate trade ID
    #   "p": "0.001",     // Price
    #   "q": "100",       // Quantity
    #   "f": 100,         // First trade ID
    #   "l": 105,         // Last trade ID
    #   "T": 123456785,   // Trade time
    #   "m": true,        // Is the buyer the market maker?
    #   "M": true         // Ignore
    # }

    let(:aggTrade_event) do
      OpenStruct.new(
        "type": "message",
        "data": {
          "stream" => "btcusdt@aggTrade",
          "data"   => {
            "e" => "aggTrade",
            "E" => 1_571_514_775_998,
            "s" => "BTCUSDT",
            "a" => 173_732_494,
            "p" => "7974.32000000",
            "q" => "0.06003700",
            "f" => 191_939_864,
            "l" => 191_939_864,
            "T" => 1_571_514_775_994,
            "m" => false,
            "M" => true
          }
        }.to_json
      )
    end

    let(:trade) do
      Arke::PublicTrade.new(6_026_899, "ENGBTC", "binance", "sell", 1242.0, 0.000037, 0.45954e-1, 1_571_640_883_296)
    end

    let(:aggTrade) do
      Arke::PublicTrade.new(173_732_494, "BTCUSDT", "binance", "buy", 0.060037, 7974.32, 0.47875424984e3, 1_571_514_775_994)
    end

    it "notifies aggTrade to registered callbacks" do
      callback = double(:callback)
      expect(callback).to receive(:call).with(aggTrade)
      binance.register_on_public_trade_cb(&callback.method(:call))
      binance.ws_read_message(:public, aggTrade_event)
    end

    it "notifies trade to registered callbacks" do
      callback = double(:callback)
      expect(callback).to receive(:call).with(trade)
      binance.register_on_public_trade_cb(&callback.method(:call))
      binance.ws_read_message(:public, trade_event)
    end
  end

  context "receive public depth events on websocket" do
    #
    # Order book price and quantity depth updates used to locally manage an order book.
    #
    # {
    #   "e": "depthUpdate", // Event type
    #   "E": 123456789,     // Event time
    #   "s": "BNBBTC",      // Symbol
    #   "U": 157,           // First update ID in event
    #   "u": 160,           // Final update ID in event
    #   "b": [              // Bids to be updated
    #     [
    #       "0.0024",       // Price level to be updated
    #       "10"            // Quantity
    #     ]
    #   ],
    #   "a": [              // Asks to be updated
    #     [
    #       "0.0026",       // Price level to be updated
    #       "100"           // Quantity
    #     ]
    #   ]
    # }

    let(:depthUpdate_event_ethusdt) do
      {
        "stream" => "ethusdt@depth",
        "data" => {
          "e" => "depthUpdate",
          "E" => 1_571_514_775_998,
          "s" => "ETHUSDT",
          "U" => 1,
          "u" => 2,
          "b" => [
            ["3", "2"],
            ["2", "2"],
            ["1", "2"]
          ],
          "a" => [
            ["5", "2"],
            ["6", "2"],
            ["7", "2"]
          ]
        }
      }
    end

    let(:depthUpdate_event_btcusdt) do
      {
        "stream" => "btcusdt@depth",
        "data" => {
          "e" => "depthUpdate",
          "E" => 1_571_514_775_998,
          "s" => "BTCUSDT",
          "U" => 1,
          "u" => 2,
          "b" => [
            ["30", "2"],
            ["20", "2"],
            ["10", "2"]
          ],
          "a" => [
            ["50", "2"],
            ["60", "2"],
            ["70", "2"]
          ]
        }
      }
    end

    let(:binance) do
      b = Arke::Exchange::Binance.new({})
      b.apply_flags(Arke::Helpers::Flags::LISTEN_PUBLIC_ORDERBOOK)
      b.initialize_orderbook("ETHUSDT")
      b.initialize_orderbook("BTCUSDT")
      b
    end

    it "using orderbook cached by websocket" do
      binance.send(:ws_read_public_message, depthUpdate_event_ethusdt)
      binance.send(:ws_read_public_message, depthUpdate_event_btcusdt)
      orderbookETH = binance.update_orderbook("ETHUSDT")
      expect(orderbookETH[:buy].to_hash).to eq(
        3.to_d => 2.to_d,
        2.to_d => 2.to_d,
        1.to_d => 2.to_d
      )
      expect(orderbookETH[:sell].to_hash).to eq(
        5.to_d => 2.to_d,
        6.to_d => 2.to_d,
        7.to_d => 2.to_d
      )
      orderbookBTC = binance.update_orderbook("BTCUSDT")
      expect(orderbookBTC[:buy].to_hash).to eq(
        30.to_d => 2.to_d,
        20.to_d => 2.to_d,
        10.to_d => 2.to_d
      )
      expect(orderbookBTC[:sell].to_hash).to eq(
        50.to_d => 2.to_d,
        60.to_d => 2.to_d,
        70.to_d => 2.to_d
      )
    end

    it "orderbook size will be WS_ORDERBOOK_MIN_CACHE_SIZE if current size exeeced WS_ORDERBOOK_MAX_CACHE_SIZE and return with sorted prices" do
      stub_const("Arke::Exchange::Binance::WS_ORDERBOOK_MIN_CACHE_SIZE", 1)
      stub_const("Arke::Exchange::Binance::WS_ORDERBOOK_MAX_CACHE_SIZE", 2)
      binance.send(:ws_read_public_message, depthUpdate_event_ethusdt)
      orderbook = binance.update_orderbook("ETHUSDT")
      expect(orderbook[:buy].to_hash.keys.length).to eq(1)
      expect(orderbook[:buy].to_hash).to eq(
        3.to_d => 2.to_d
      )
      expect(orderbook[:sell].to_hash.keys.length).to eq(1)
      expect(orderbook[:sell].to_hash).to eq(
        5.to_d => 2.to_d
      )
    end

    it "updates an existing price point" do
      binance.send(:ws_read_public_message, depthUpdate_event_ethusdt)
      binance.send(:ws_read_public_message, depthUpdate_event_ethusdt.merge(
        "data" => depthUpdate_event_ethusdt["data"].merge(
          "U" => 3,
          "u" => 4,
          "b" => [
            ["1", "0"],
            ["3.5", "2"]
          ],
          "a" => [
            ["5", "0"],
            ["8", "2"]
          ]
        )
      ))
      orderbook = binance.update_orderbook("ETHUSDT")
      expect(orderbook[:buy].to_hash).to eq(
        3.5.to_d => 2.to_d,
        3.to_d => 2.to_d,
        2.to_d => 2.to_d
      )
      expect(orderbook[:sell].to_hash).to eq(
        6.to_d => 2.to_d,
        7.to_d => 2.to_d,
        8.to_d => 2.to_d
      )
    end

    it "websocket will not disconnect if it is in correct sequences." do
      binance.send(:ws_read_public_message, depthUpdate_event_ethusdt)
      ws = double(close: true)
      binance.instance_variable_set(:@ws, ws)
      expect(ws).not_to receive(:close)
      binance.send(:ws_read_public_message, depthUpdate_event_ethusdt.merge(
        "data" => depthUpdate_event_ethusdt["data"].merge("U" => 3, "u" => 10)
      ))
      binance.send(:ws_read_public_message, depthUpdate_event_ethusdt.merge(
        "data" => depthUpdate_event_ethusdt["data"].merge("U" => 11, "u" => 12)
      ))
    end

    it "disconnects websocket if it detects a sequence out of order" do
      binance.send(:ws_read_public_message, depthUpdate_event_ethusdt)
      ws = double(close: true)
      binance.instance_variable_set(:@ws, ws)
      expect(ws).to receive(:close)
      binance.send(:ws_read_public_message, depthUpdate_event_ethusdt)
      expect(binance.books.keys.length).to eq(0)
    end
  end

  context "market_config" do
    it "returns market configuration" do
      expect(binance.market_config("ETHUSDT")).to eq(
        "id"               => "ETHUSDT",
        "base_unit"        => "ETH",
        "quote_unit"       => "USDT",
        "min_price"        => 0.01,
        "max_price"        => 10_000_000,
        "min_amount"       => 0.00001,
        "amount_precision" => 5,
        "price_precision"  => 2
      )
    end

    it "returns market configuration with precision considering PRICE_FILTER tickSize" do
      expect(binance.market_config("OMGUSDT")).to eq(
        "id"               => "OMGUSDT",
        "base_unit"        => "OMG",
        "quote_unit"       => "USDT",
        "min_price"        => 0.0001,
        "max_price"        => 1000,
        "min_amount"       => 0.01,
        "amount_precision" => 2,
        "price_precision"  => 4
      )
    end
  end
end
