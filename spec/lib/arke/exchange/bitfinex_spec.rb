# frozen_string_literal: true

describe Arke::Exchange::Bitfinex do
  include_context "mocked bitfinex"

  let(:config) { YAML.safe_load(file_fixture("test_config.yaml")) }
  let(:market_id) { "ETHUSD" }

  let(:bitfinex_config) do
    {
      "driver"     => "bitfinex",
      "host"       => "api.bitfinex.com",
      "key"        => "Uwg8wqlxueiLCsbTXjlogviL8hdd60",
      "secret"     => "OwpadzSYOSkzweoJkjPrFeVgjOwOuxVHk8FXIlffdWw",
      "rate_limit" => 1.0
    }
  end
  let(:strategy) { Arke::Strategy::Copy.new(config) }
  let(:bitfinex) { Arke::Exchange::Bitfinex.new(bitfinex_config) }
  let!(:market) { Arke::Market.new(market_id, bitfinex) }

  context "market_config" do
    it "generates market configuration" do
      expect(bitfinex.market_config("BTCUST")).to eq(
        "id"               => "btcust",
        "base_unit"        => "btc",
        "quote_unit"       => "ust",
        "min_price"        => nil,
        "max_price"        => nil,
        "min_amount"       => 0.0006.to_d,
        "amount_precision" => 8.to_d,
        "price_precision"  => 5.to_d
      )
      expect(bitfinex.market_config("cnh:cnht")).to eq(
        "id"               => "cnh:cnht",
        "base_unit"        => "cnh",
        "quote_unit"       => "cnht",
        "min_price"        => nil,
        "max_price"        => nil,
        "min_amount"       => 6.to_d,
        "amount_precision" => 8.to_d,
        "price_precision"  => 5.to_d
      )
    end
  end

  context "Bitfinex class" do
    let(:data_create) { [1, 10, 20] }
    let(:data_create_sell) { [2, 22, -33] }
    let(:data_delete) { [3, 0, 44] }

    it "#new_order with positive amount" do
      price, _count, amount = data_create
      order = bitfinex.new_order(data_create)

      expect(order.price).to eq(price)
      expect(order.amount).to eq(amount)
      expect(order.side).to eq(:buy)
    end

    it "#new_order with negative amount" do
      price, _count, amount = data_create_sell
      order = bitfinex.new_order(data_create_sell)

      expect(order.price).to eq(price)
      expect(order.amount).to eq(-amount)
      expect(order.side).to eq(:sell)
    end

    it "#process_data creates order" do
      skip "bitfinex websocket needs to subscribe to every market and detect on which market event come"
      # expect(market.orderbook).to receive(:update)
      # bitfinex.process_data(data_create)
    end

    it "#process_data deletes order" do
      skip "bitfinex websocket needs to subscribe to every market and detect on which market event come"
      # expect(bitfinex.orderbook).to receive(:delete)
      # bitfinex.process_data(data_delete)
    end
  end

  context "websocket messages processing" do
    let(:snapshot_message) do
      [69_586,
       [
         [22_814_737_094, 141, 3.5459735],
         [22_814_761_433, 141, 1678.72933611],
         [22_814_767_295, 141, 2.28948142],
         [22_814_776_345, 141, 572.89016357],
         [22_814_807_549, 141, 6.848292],
         [22_814_800_273, 141.01, -0.56493047],
         [22_814_805_880, 141.01, -14],
         [22_814_813_532, 141.01, -12.3841162],
         [22_814_813_983, 141.01, -1.56],
         [22_814_799_021, 141.1322692908, -2.32966444]
       ]]
    end

    let(:single_order) { [69_586, [22_814_737_094, 141, 2.45]] }

    it "processes single order in message" do
      # expect(bitfinex).to receive(:process_channel_message)
      expect(bitfinex).to receive(:process_data)

      bitfinex.process_message(single_order)
    end

    it "processes list of orders" do
      n = snapshot_message[1].length
      expect(bitfinex).to receive(:process_data).exactly(n).times

      bitfinex.process_message(snapshot_message)
    end
  end

  context "get balances" do
    let(:bitfinex_unauthorized) do
      Arke::Exchange::Bitfinex.new(
        "driver"     => "bitfinex",
        "host"       => "api.bitfinex.com",
        "key"        => "unknown",
        "secret"     => "OwpadzSYOSkzweoJkjPrFeVgjOwOuxVHk8FXIlffdWw",
        "rate_limit" => 1.0
      )
    end

    it "returns error whe inccorect API key" do
      response = bitfinex_unauthorized.get_balances
      expect(response["message"]).to eq "Could not find a key matching the given X-BFX-APIKEY."
    end

    it "fetchs the account balance in arke format" do
      response = bitfinex.get_balances
      expect(response).to eq(
        [
          {
            "currency" => "ETH",
            "total"    => 100.12,
            "free"     => 100.12,
            "locked"   => 0.0,
          },
          {
            "currency" => "USD",
            "total"    => 110.0,
            "free"     => 100.0,
            "locked"   => 10.0,
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
      expect(market.open_orders[:buy][0.02]).to eq(123 => Arke::Order.new("ETHUSD", 0.02, 0.2, :buy))
    end
  end

  context "create order" do
    let(:order) { Arke::Order.new("ETHUSD", 135.84, 6.62227, :buy) }

    it "successfull" do
      order.apply_requirements(bitfinex)
      response = bitfinex.create_order(order)
                         .slice("symbol", "price", "side", "original_amount")

      expect(response).to eq(
        "symbol"          => "ethusd",
        "price"           => "135.84",
        "side"            => "buy",
        "original_amount" => "6.62227"
      )
    end
  end

  context "public trade event" do
    let(:trade) do
      Arke::PublicTrade.new(418_288_902, "ETHUSD", "bitfinex", "sell", 0.1, 262.69, 26.269, 1_582_036_305_000)
    end
    let(:trade_event) do
      OpenStruct.new(
        "type": "message",
        "data": '[207,"tu","34624926-ETHUSD",418288902,1582036305,262.69,-0.1]'
      )
    end

    it "notifies public trade to registered callbacks" do
      callback = double(:callback)
      expect(callback).to receive(:call).with(trade)
      bitfinex.register_on_public_trade_cb(&callback.method(:call))
      bitfinex.ws_read_message(:public, trade_event)
    end
  end
end
