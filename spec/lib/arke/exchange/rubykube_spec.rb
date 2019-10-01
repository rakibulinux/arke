# frozen_string_literal: true

describe Arke::Exchange::Rubykube do
  include_context "mocked rubykube"

  before(:all) { Arke::Log.define }

  let(:strategy_config) { {} }
  let(:exchange_config) do
    {
      "driver" => "rubykube",
      "host"   => "http://www.devkube.com",
      "key"    => @authorized_api_key,
      "secret" => SecureRandom.hex
    }
  end

  let!(:market) { Arke::Market.new(market_config, rubykube) }

  let(:market_config) do
    {
      "id"    => "ETHUSD",
      "base"  => "ETH",
      "quote" => "USD",
    }
  end

  let(:strategy) { Arke::Strategy::Copy.new(strategy_config) }
  let(:order) { Arke::Order.new("ethusd", 1, 1, :buy) }
  let(:rubykube) { Arke::Exchange::Rubykube.new(exchange_config) }

  context "rubykube#create_order" do
    it "gets 403 on request with wrong api key" do
      rubykube.instance_variable_set(:@api_key, SecureRandom.hex)

      expect(rubykube.create_order(order).id).to eq nil
    end

    it "doesn't updates open_orders after create" do
      ord = rubykube.create_order(order)
      expect(ord.id).to be_between(1, 1000)
      expect(market.open_orders.contains?(order.side, order.price)).to eq(false)
    end
  end

  context "rubykube#fetch_openorders" do
    it "saves opened orders" do
      market.fetch_openorders

      expect(market.open_orders.contains?(:sell, 138.87)).to eq(true)
      expect(market.open_orders.contains?(:buy, 233.98)).to eq(true)
      expect(market.open_orders.contains?(:sell, 138.87)).to eq(true)
      expect(market.open_orders.contains?(:buy, 138.76)).to eq(true)
    end
  end

  context "rubykube#get_balances" do
    it "get balances of all users accounts" do
      expect(rubykube.get_balances).to eq(
        [
          {"currency" => "eth", "total" => 0.0, "free" => 0.0, "locked" => 0.0},
          {"currency" => "fth", "total" => 1_000_000.0, "free" => 1_000_000.0, "locked" => 0.0},
          {"currency" => "trst", "total" => 0.0, "free" => 0.0, "locked" => 0.0},
          {"currency" => "usd", "total" => 1_000_000.0, "free" => 999_990.0, "locked" => 10.0},
        ]
      )
    end
  end

  context "rubykube#stop_order" do
    let(:order) { Arke::Order.new("ethusd", 1, 1, :buy, "limit", 42) }

    it "sets proper url when stop order" do
      market.add_order(order)
      response = market.stop_order(order)

      expect(response.env.url.to_s).to match(%r{peatio/market/orders/\d+/cancel})
    end

    it "sets proper header when stop order" do
      market.add_order(order)
      response = market.stop_order(order)

      expect(response.env.request_headers.keys).to include("X-Auth-Apikey", "X-Auth-Nonce", "X-Auth-Signature", "Content-Type")
      expect(response.env.request_headers).to include("X-Auth-Apikey" => @authorized_api_key)
    end
  end

  context "rubykube#process_message" do
    let(:order) { Arke::Order.new("ethusd", 1, 1, :buy) }
    let(:updated_order) { Arke::Order.new("ETHUSD", 1.0, 0.5, :buy) }
    let(:order_partially_fullfilled) { {"order" => {"id" => order_id, "at" => 1_546_605_232, "market" => "ethusd", "kind" => "bid", "price" => "1", "state" => "wait", "remaining_volume" => "0.5", "origin_volume" => "1"}} }
    let(:order_id) { rubykube.create_order(order).id }
    let(:order_cancelled) { {"order" => {"id" => order_id, "at" => 1_546_605_232, "market" => "ethusd", "kind" => "bid", "price" => "1", "state" => "cancel", "remaining_volume" => "1.0", "origin_volume" => "1.0"}} }
    let(:trade_executed) { {"trade" => {"ask_id" => order_id, "at" => 1_546_605_232, "bid_id" => order_id, "id" => order_id, "kind" => "ask", "market" => "ethusd", "price" => "1", "volume" => "1.0"}} }

    before do
      rubykube.create_order(order).id
    end

    it "updates order when partially fullfilled" do
      rubykube.send(:process_message, order_partially_fullfilled)
      expect(market.open_orders[:buy][1].length).to eq(1)
      expect(market.open_orders[:buy][1][order_id]).to eq(updated_order)
    end

    it "removes order when cancelled" do
      rubykube.send(:process_message, order_cancelled)
      expect(market.open_orders[:buy].length).to eq(0)
    end

    it "sends a callback on executed trade" do
      expect(rubykube).to receive(:notify_trade).twice
      rubykube.send(:process_message, trade_executed)
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
