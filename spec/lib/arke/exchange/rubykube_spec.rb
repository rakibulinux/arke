describe Arke::Exchange::Rubykube do
  include_context "mocked rubykube"

  before(:all) { Arke::Log.define }

  let(:strategy_config) { {} }
  let(:exchange_config) {
    {
      "driver" => "rubykube",
      "host" => "http://www.devkube.com",
      "key" => @authorized_api_key,
      "secret" => SecureRandom.hex,
      "market" => {
        "id" => "ETHUSD",
        "base" => "ETH",
        "quote" => "USD",
      },
    }
  }
  let(:strategy) { Arke::Strategy::Copy.new(strategy_config) }
  let(:order) { Arke::Order.new("ethusd", 1, 1, :buy) }
  let(:rubykube) { Arke::Exchange::Rubykube.new(exchange_config) }

  context "rubykube#create_order" do
    it "sets proper url when create order" do
      response = rubykube.create_order(order)

      expect(response.env.url.to_s).to include("peatio/market/orders")
    end

    it "sets proper header when create order" do
      response = rubykube.create_order(order)

      expect(response.env.request_headers.keys).to include("X-Auth-Apikey", "X-Auth-Nonce", "X-Auth-Signature", "Content-Type")
      expect(response.env.request_headers).to include("X-Auth-Apikey" => @authorized_api_key)
    end

    it "gets 403 on request with wrong api key" do
      rubykube.instance_variable_set(:@api_key, SecureRandom.hex)

      expect(rubykube.create_order(order).status).to eq 403
    end

    it "updates open_orders after create" do
      rubykube.create_order(order)

      expect(rubykube.open_orders.contains?(order.side, order.price)).to eq(true)
    end
  end

  context "rubykube#fetch_openorders" do
    it "saves opened orders" do
      rubykube.fetch_openorders

      expect(rubykube.open_orders.contains?(:sell, 138.87)).to eq(true)
      expect(rubykube.open_orders.contains?(:buy, 233.98)).to eq(true)
      expect(rubykube.open_orders.contains?(:sell, 138.87)).to eq(true)
      expect(rubykube.open_orders.contains?(:buy, 138.76)).to eq(true)
    end
  end

  context "rubykube#get_balances" do
    it "get balances of all users accounts" do
      expect(rubykube.get_balances).to eq([
        { "currency" => "eth", "total" => 0.0, "free" => 0.0, "locked" => 0.0 },
        { "currency" => "fth", "total" => 1000000.0, "free" => 1000000.0, "locked" => 0.0 },
        { "currency" => "trst", "total" => 0.0, "free" => 0.0, "locked" => 0.0 },
        { "currency" => "usd", "total" => 1000000.0, "free" => 999990.0, "locked" => 10.0 },
      ])
    end
  end

  context "rubykube#stop_order" do
    let(:order_id) { rubykube.create_order(order).body["id"] }

    it "sets proper url when stop order" do
      response = rubykube.stop_order(order_id)

      expect(response.env.url.to_s).to match(/peatio\/market\/orders\/\d+\/cancel/)
    end

    it "sets proper header when stop order" do
      response = rubykube.stop_order(order_id)

      expect(response.env.request_headers.keys).to include("X-Auth-Apikey", "X-Auth-Nonce", "X-Auth-Signature", "Content-Type")
      expect(response.env.request_headers).to include("X-Auth-Apikey" => @authorized_api_key)
    end
  end

  context "rubykube#process_message" do
    let(:order) { Arke::Order.new("ethusd", 1, 1, :buy) }
    let(:updated_order) { Arke::Order.new("ETHUSD", 1.0, 0.5, :buy) }
    let(:order_partially_fullfilled) { { "order" => { "id" => order_id, "at" => 1546605232, "market" => "ethusd", "kind" => "bid", "price" => "1", "state" => "wait", "remaining_volume" => "0.5", "origin_volume" => "1" } } }
    let(:order_id) { rubykube.create_order(order).body["id"] }
    let(:order_cancelled) { { "order" => { "id" => order_id, "at" => 1546605232, "market" => "ethusd", "kind" => "bid", "price" => "1", "state" => "cancel", "remaining_volume" => "1.0", "origin_volume" => "1.0" } } }
    let(:trade_executed) { { "trade" => { "ask_id" => order_id, "at" => 1546605232, "bid_id" => order_id, "id" => order_id, "kind" => "ask", "market" => "ethusd", "price" => "1", "volume" => "1.0" } } }

    before do
      rubykube.create_order(order).body["id"]
    end

    it "updates order when partially fullfilled" do
      rubykube.send(:process_message, order_partially_fullfilled)
      expect(rubykube.open_orders[:buy][1].length).to eq(1)
      expect(rubykube.open_orders[:buy][1][order_id]).to eq(updated_order)
    end

    it "removes order when cancelled" do
      rubykube.send(:process_message, order_cancelled)
      expect(rubykube.open_orders[:buy].length).to eq(0)
    end

    it "sends a callback on executed trade" do
      expect(rubykube).to receive(:notify_trade)
      rubykube.send(:process_message, trade_executed)
    end
  end

  context "rubykube#cancel_all_orders" do
    let(:order) { Arke::Order.new("ethusd", 1, 1, :buy) }
    let(:order_second) { Arke::Order.new("ethusd", 1, 1, :sell) }

    before do
      rubykube.create_order(order)
      rubykube.create_order(order_second)
      rubykube.fetch_openorders
    end

    it "cancels all open orders orders" do
      rubykube.cancel_all_orders
      expect(rubykube.open_orders[:buy].length).to eq(0)
      expect(rubykube.open_orders[:sell].length).to eq(0)
    end
  end
end
