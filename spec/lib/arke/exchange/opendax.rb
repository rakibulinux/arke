# frozen_string_literal: true

describe Arke::Exchange::Opendax do
  let(:exchange_config) do
    {
      "driver" => "opendax",
      "host"   => "http://www.devkube.com",
      "key"    => @authorized_api_key,
      "secret" => SecureRandom.hex,
    }
  end
  let(:market_id) { "ethusd" }
  let(:market) { Arke::Market.new(market_id, opendax) }
  let(:order) { Arke::Order.new("ethusd", 1, 1, :buy) }
  let(:opendax) { Arke::Exchange::Opendax.new(exchange_config) }

  context "mocked opendax" do
    include_context "mocked opendax"
    before(:each) { order.apply_requirements(opendax) }

    context "opendax#create_order" do
      it "gets 403 on request with wrong api key" do
        opendax.instance_variable_set(:@api_key, SecureRandom.hex)

        expect(opendax.create_order(order).id).to eq nil
      end

      it "doesn't updates open_orders after create" do
        ord = opendax.create_order(order)
        assert_requested(:post, "http://www.devkube.com/api/v2/peatio/market/orders", times: 1) do |req|
          expect(JSON.parse(req.body)).to eq(
            "market"   => "ethusd",
            "volume"   => "1.0000",
            "price"    => "1.00",
            "side"     => "buy",
            "ord_type" => "limit"
          )
        end
        expect(ord.id).to be_between(1, 1000)
        expect(market.open_orders.contains?(order.side, order.price)).to eq(false)
      end
    end

    context "opendax#fetch_openorders" do
      it "saves opened orders" do
        market.fetch_openorders

        expect(market.open_orders.contains?(:sell, 138.87)).to eq(true)
        expect(market.open_orders.contains?(:buy, 233.98)).to eq(true)
        expect(market.open_orders.contains?(:sell, 138.87)).to eq(true)
        expect(market.open_orders.contains?(:buy, 138.76)).to eq(true)
      end
    end

    context "opendax#get_balances" do
      it "get balances of all users accounts" do
        expect(opendax.get_balances).to eq(
          [
            {"currency" => "eth", "total" => 0.0, "free" => 0.0, "locked" => 0.0},
            {"currency" => "fth", "total" => 1_000_000.0, "free" => 1_000_000.0, "locked" => 0.0},
            {"currency" => "trst", "total" => 0.0, "free" => 0.0, "locked" => 0.0},
            {"currency" => "usd", "total" => 1_000_000.0, "free" => 999_990.0, "locked" => 10.0},
          ]
        )
      end
    end

    context "opendax#stop_order" do
      let(:order) { Arke::Order.new("ethusd", 1, 1, :buy, "limit", 42) }

      it "cancels an open order and doesn't notify when the cancel is pending" do
        stub_request(:post, %r{peatio/market/orders/\d+/cancel})
          .with(headers: {"X-Auth-Apikey" => @authorized_api_key})
          .to_return(
            status:  201,
            body:    {
              "id"               => 51_384,
              "side"             => "sell",
              "ord_type"         => "limit",
              "price"            => "178.92",
              "avg_price"        => "0.0",
              "state"            => "wait",
              "market"           => "ethusd",
              "created_at"       => "2020-01-30T14:08:55+01:00",
              "updated_at"       => "2020-01-30T14:08:55+01:00",
              "origin_volume"    => "1.0",
              "remaining_volume" => "1.0",
              "executed_volume"  => "0.0",
              "trades_count"     => 0,
            }.to_json,
            headers: {}
          )

        cb = double("on_deleted_order callback", call: true)
        opendax.register_on_deleted_order(&cb.method(:call))
        expect(cb).to_not receive(:call)
        market.stop_order(order)
      end

      it "cancels an order already closed and notifies because we may have missed the confirmation from the websocket" do
        stub_request(:post, %r{peatio/market/orders/\d+/cancel})
          .with(headers: {"X-Auth-Apikey" => @authorized_api_key})
          .to_return(
            status:  201,
            body:    {
              "id"               => 51_384,
              "side"             => "sell",
              "ord_type"         => "limit",
              "price"            => "178.92",
              "avg_price"        => "0.0",
              "state"            => "cancel",
              "market"           => "ethusd",
              "created_at"       => "2020-01-30T14:08:55+01:00",
              "updated_at"       => "2020-01-30T14:08:55+01:00",
              "origin_volume"    => "1.0",
              "remaining_volume" => "1.0",
              "executed_volume"  => "0.0",
              "trades_count"     => 0,
            }.to_json,
            headers: {}
          )

        cb = double("on_deleted_order callback", call: true)
        rubykube.register_on_deleted_order(&cb.method(:call))
        expect(cb).to receive(:call).once.with(order)
        market.stop_order(order)
      end

      it "raises if we try to cancel a non existing order" do
        stub_request(:post, %r{peatio/market/orders/\d+/cancel})
          .with(headers: {"X-Auth-Apikey" => @authorized_api_key})
          .to_return(
            status:  201,
            body:    {
              "errors": [
                "record.not_found",
              ],
            }.to_json,
            headers: {}
          )
        expect { market.stop_order(order) }.to raise_error(StandardError)
      end
    end

    context "rubykube#process_message" do
      let(:order) { Arke::Order.new("ethusd", 1, 1, :buy) }
      let(:updated_order) { Arke::Order.new("ETHUSD", 1.0, 0.5, :buy) }
      let(:order_partially_fullfilled) do
        OpenStruct.new(
          "data": {
            "order" => {
              "id"               => order_id,
              "market"           => "ethusd",
              "kind"             => "bid",
              "side"             => "sell",
              "ord_type"         => "limit",
              "price"            => "1",
              "state"            => "wait",
              "remaining_volume" => "0.5",
              "origin_volume"    => "1",
              "executed_volume"  => "0.0",
              "avg_price"        => "0.0",
              "at"               => 1_570_537_877,
              "created_at"       => 1_570_537_877,
              "updated_at"       => 1_570_538_020,
              "trades_count"     => 0,
            },
          }.to_json
        )
      end

      let(:order_id) { rubykube.create_order(order).id }
      let(:order_cancelled) do
        OpenStruct.new("data": {"order" => {"id" => order_id, "at" => 1_546_605_232, "market" => "ethusd", "kind" => "bid", "price" => "1", "state" => "cancel", "remaining_volume" => "1.0", "origin_volume" => "1.0"}}.to_json)
      end

      let(:trade_executed) do
        OpenStruct.new("data": {"trade" => {"ask_id" => order_id, "at" => 1_546_605_232, "bid_id" => order_id, "id" => order_id, "kind" => "ask", "market" => "ethusd", "price" => "1", "volume" => "1.0"}}.to_json)
      end

      before do
        rubykube.create_order(order).id
      end

      it "updates order when partially fullfilled" do
        market
        rubykube.send(:ws_read_message, :private, order_partially_fullfilled)
        expect(market.open_orders[:buy][1].length).to eq(1)
        expect(market.open_orders[:buy][1][order_id]).to eq(updated_order)
      end

      it "removes order when cancelled" do
        rubykube.send(:ws_read_message, :private, order_cancelled)
        expect(market.open_orders[:buy].length).to eq(0)
      end

      it "sends a callback on executed trade" do
        expect(rubykube).to receive(:notify_private_trade).twice
        rubykube.send(:ws_read_message, :private, trade_executed)
      end
    end

    context "rubykube#cancel_all_orders" do
      let(:order) { Arke::Order.new("ethusd", 1, 1, :buy, "limit", 12) }
      let(:order_second) { Arke::Order.new("ethusd", 1, 1, :sell, "limit", 13) }

      before do
        market.add_order(order)
        market.add_order(order_second)
      end

      it "cancels all open orders orders" do
        market.cancel_all_orders
        expect(market.open_orders[:buy].length).to eq(1)
        expect(market.open_orders[:sell].length).to eq(1)
      end
    end
  end

  context "rubykube#market_config after peatio 2.2.14" do
    include_context "mocked rubykube"
    it "generates market configuration" do
      expect(rubykube.market_config("btcusd")).to eq(
        "id"               => "btcusd",
        "base_unit"        => "btc",
        "quote_unit"       => "usd",
        "min_price"        => 100.0,
        "max_price"        => 100_000.0,
        "min_amount"       => 0.0005,
        "amount_precision" => 6,
        "price_precision"  => 2
      )
    end
  end

  context "rubykube#market_config before peatio 2.2.14" do
    it "generates market configuration" do
      stub_request(:get, %r{peatio/public/markets})
        .to_return(
          status:  200,
          body:    [
            {
              "id"             => "btcusd",
              "name"           => "BTC/USD",
              "ask_unit"       => "btc",
              "bid_unit"       => "usd",
              "min_ask_price"  => "100.0",
              "max_bid_price"  => "100000.0",
              "min_ask_amount" => "0.0005",
              "min_bid_amount" => "0.0005",
              "ask_precision"  => 6,
              "bid_precision"  => 2,
            },
          ].to_json,
          headers: {}
        )
      expect(rubykube.market_config("btcusd")).to eq(
        "id"               => "btcusd",
        "base_unit"        => "btc",
        "quote_unit"       => "usd",
        "min_price"        => 100,
        "max_price"        => 100_000,
        "min_amount"       => 0.0005,
        "amount_precision" => 6,
        "price_precision"  => 2
      )
    end
  end

  context "rubykube#market_config misconfiguration" do
    it "doesn't raise error for missing non required fields" do
      stub_request(:get, %r{peatio/public/markets})
        .to_return(
          status:  200,
          body:    [
            {
              "id"               => "btcusd",
              "base_unit"        => "btc",
              "quote_unit"       => "usd",
              "amount_precision" => 6,
              "price_precision"  => 2,
              "state"            => "enabled",
            },
          ].to_json,
          headers: {}
        )
      expect(rubykube.market_config("btcusd")).to eq(
        "id"               => "btcusd",
        "base_unit"        => "btc",
        "quote_unit"       => "usd",
        "min_price"        => nil,
        "max_price"        => nil,
        "min_amount"       => nil,
        "amount_precision" => 6,
        "price_precision"  => 2
      )
    end

    it "raises error if id is missing" do
      stub_request(:get, %r{peatio/public/markets})
        .to_return(
          status:  200,
          body:    [
            {
              "base_unit"        => "btc",
              "quote_unit"       => "usd",
              "amount_precision" => 6,
              "price_precision"  => 2,
            },
          ].to_json,
          headers: {}
        )
      expect { rubykube.market_config("btcusd") }.to raise_error("Market btcusd not found")
    end

    it "raises error if base_unit is missing" do
      stub_request(:get, %r{peatio/public/markets})
        .to_return(
          status:  200,
          body:    [
            {
              "id"               => "btcusd",
              "quote_unit"       => "usd",
              "amount_precision" => 6,
              "price_precision"  => 2,
              "state"            => "enabled",
            },
          ].to_json,
          headers: {}
        )
      expect { rubykube.market_config("btcusd") }.to raise_error(/base_unit/)
    end

    it "raises error if quote_unit is missing" do
      stub_request(:get, %r{peatio/public/markets})
        .to_return(
          status:  200,
          body:    [
            {
              "id"               => "btcusd",
              "base_unit"        => "btc",
              "amount_precision" => 6,
              "price_precision"  => 2,
              "state"            => "enabled",
            },
          ].to_json,
          headers: {}
        )
      expect { rubykube.market_config("btcusd") }.to raise_error(/quote_unit/)
    end

    it "raises error if amount_precision is missing" do
      stub_request(:get, %r{peatio/public/markets})
        .to_return(
          status:  200,
          body:    [
            {
              "id"              => "btcusd",
              "base_unit"       => "btc",
              "quote_unit"      => "usd",
              "price_precision" => 2,
              "state"           => "enabled",
            },
          ].to_json,
          headers: {}
        )
      expect { rubykube.market_config("btcusd") }.to raise_error(/amount_precision/)
    end

    it "raises error if price_precision is missing" do
      stub_request(:get, %r{peatio/public/markets})
        .to_return(
          status:  200,
          body:    [
            {
              "id"               => "btcusd",
              "base_unit"        => "btc",
              "quote_unit"       => "usd",
              "amount_precision" => 6,
              "state"            => "enabled",
            },
          ].to_json,
          headers: {}
        )
      expect { rubykube.market_config("btcusd") }.to raise_error(/price_precision/)
    end
  end

  context "finex enabled" do
    include_context "mocked finex"

    let(:exchange_config) do
      {
        "driver" => "opendax",
        "host"   => "http://www.devkube.com",
        "key"    => @authorized_api_key,
        "secret" => SecureRandom.hex,
        "finex"  => true
      }
    end
    let(:order) { Arke::Order.new("ethusd", 1, 2, :buy) }
    before(:each) { order.apply_requirements(opendax) }

    it "doesn't updates open_orders after create" do
      ord = opendax.create_order(order)
      expect(ord.id).to be_nil
      expect(market.open_orders.contains?(order.side, order.price)).to eq(false)
      assert_requested(:post, "http://www.devkube.com/api/v2/finex/market/orders", times: 1) do |req|
        expect(JSON.parse(req.body)).to eq(
          "market" => "ethusd",
          "amount" => "2.0000",
          "price"  => "1.00",
          "side"   => "buy",
          "type"   => "limit"
        )
      end
    end

    it "cancels an open order and doesn't notify when the cancel is pending" do
      o = Arke::Order.new("ethusd", 1, 1, :buy, "limit", 42)
      cb = double("on_deleted_order callback", call: true)
      opendax.register_on_deleted_order(&cb.method(:call))
      expect(cb).to_not receive(:call)
      market.stop_order(o)
    end
  end

  context "maintain market public orderbook incrementally" do
    let(:snapshot) do
      {
        "ethusd.ob-snap" => {
          "asks"     => [
            ["252.32", "0.2"],
            ["252.92", "0.90403"],
            ["253.08", "0.73563"],
          ],
          "bids"     => [
            ["249.16", "0.20603"],
            ["248.69", "0.09944"],
            ["248.66", "0.05057"],
          ],
          "sequence" => 6111,
        },
      }
    end

    it "updates an existing price point" do
      opendax.send(:ws_read_private_message, snapshot)
      opendax.send(:ws_read_private_message, "ethusd.ob-inc" => {"asks" => ["252.32", "0.1"], "sequence" => 6112})
      expect(opendax.update_orderbook("ethusd")[:buy].to_hash).to eq(
        249.16.to_d => 0.20603.to_d,
        248.69.to_d => 0.09944.to_d,
        248.66.to_d => 0.05057.to_d
      )
      expect(opendax.update_orderbook("ethusd")[:sell].to_hash).to eq(
        252.32.to_d => 0.1.to_d,
        252.92.to_d => 0.90403.to_d,
        253.08.to_d => 0.73563.to_d
      )
    end

    it "deletes an existing price point" do
      opendax.send(:ws_read_private_message, snapshot)
      opendax.send(:ws_read_private_message, "ethusd.ob-inc" => {"asks" => ["252.32", "0.0"], "sequence" => 6112})
      opendax.send(:ws_read_private_message, "ethusd.ob-inc" => {"bids" => ["248.69", "0.0"], "sequence" => 6113})
      expect(opendax.update_orderbook("ethusd")[:buy].to_hash).to eq(
        249.16.to_d => 0.20603.to_d,
        248.66.to_d => 0.05057.to_d
      )
      expect(opendax.update_orderbook("ethusd")[:sell].to_hash).to eq(
        252.92.to_d => 0.90403.to_d,
        253.08.to_d => 0.73563.to_d
      )
    end

    it "deletes an existing price point (again)" do
      opendax.send(:ws_read_private_message, snapshot)
      opendax.send(:ws_read_private_message, "ethusd.ob-inc" => {"asks" => ["252.32", ""], "sequence" => 6112})
      opendax.send(:ws_read_private_message, "ethusd.ob-inc" => {"bids" => ["248.69", ""], "sequence" => 6113})
      expect(opendax.update_orderbook("ethusd")[:buy].to_hash).to eq(
        249.16.to_d => 0.20603.to_d,
        248.66.to_d => 0.05057.to_d
      )
      expect(opendax.update_orderbook("ethusd")[:sell].to_hash).to eq(
        252.92.to_d => 0.90403.to_d,
        253.08.to_d => 0.73563.to_d
      )
    end

    it "disconnects websocket if it detects a sequence out of order" do
      opendax.send(:ws_read_private_message, snapshot)
      ws = double(close: true)
      opendax.instance_variable_set(:@ws, ws)
      expect(ws).to receive(:close)
      opendax.send(:ws_read_private_message, "ethusd.ob-inc" => {"asks" => ["252.32", ""], "sequence" => 6113})
    end
  end

  context "update balances on ranger messages" do
    include_context "mocked opendax"

    let(:balances_event) do
      {
        "balances" => {
          "btc" => %w[0.998 0.002],
          "eth" => %w[1000000000 0],
        }
      }
    end

    it "updates an existing price point" do
      opendax.send(:ws_read_private_message, balances_event)
      expect(opendax.fetch_balances).to eq(
        [
          {
            "currency" => "btc",
            "free"     => 0.998,
            "locked"   => 0.002,
            "total"    => 1,
          },
          {
            "currency" => "eth",
            "free"     => 1_000_000_000,
            "locked"   => 0,
            "total"    => 1_000_000_000,
          },
        ]
      )
      expect(opendax.balance("btc")).to eq(
        "currency" => "btc",
        "free"     => 0.998,
        "locked"   => 0.002,
        "total"    => 1,
      )
      expect(opendax.balance("eth")).to eq(
        "currency" => "eth",
        "free"     => 1_000_000_000,
        "locked"   => 0,
        "total"    => 1_000_000_000,
      )
      expect(opendax.balance("trst")).to be_nil
    end
  end
end
