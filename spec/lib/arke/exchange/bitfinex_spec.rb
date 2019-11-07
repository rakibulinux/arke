# frozen_string_literal: true

describe Arke::Exchange::Bitfinex do
  include_context "mocked bitfinex"

  let(:config) { YAML.load_file("spec/support/fixtures/test_config.yaml") }
  let(:market_config) do
    {
      "id"             => "ETHUSD",
      "base"           => "ETH",
      "quote"          => "USD",
      "min_ask_amount" => 0.01,
      "min_bid_amount" => 0.01,
    }
  end
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
  let!(:market) { Arke::Market.new(market_config, bitfinex) }

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
      response = bitfinex.create_order(order)
                         .slice("symbol", "price", "side", "original_amount")

      expect(response).to eq(
        "symbol"          => order.market.downcase.to_s,
        "price"           => order.price.to_s,
        "side"            => order.side.to_s,
        "original_amount" => order.amount.to_s
      )
    end
  end

  context "get_kline" do
    it "returns last k-line" do
      expect(bitfinex.get_kline(market.id)).to eq(
        [1573122840000,185.82,185.82,185.82,185.82,4.24897052]
      )
    end

    it "returns historical k-line" do
      expect(bitfinex.get_kline(market.id, "5m", 123)).to eq(
        [
          [1573123020000,186,186,186,186,37.68113751],
          [1573122960000,186,186,186,186,21.09442441],
          [1573122900000,185.83,186,186,185.83,58.82140792],
          [1573122840000,185.82,185.83,185.83,185.82,4.74146302],
          [1573122780000,185.82,185.82,185.82,185.82,0.07885584]
        ]
      )
    end
  end
end
