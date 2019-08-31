require "rails_helper"

describe Arke::Strategy::Example1 do
  include_context "mocked rubykube"

  let(:strategy) { Arke::Strategy::Example1.new([source], target, config, executor, nil) }
  let(:config) do
    {
      "id" => 1,
      "type" => "strategy1",
      "params" => {
        "spread_bids" => 0.01,
        "spread_asks" => 0.2,
        "limit_bids" => 1.0,
        "limit_asks" => 1.5,
        "levels_algo" => "constant",
        "levels_size" => 0.01,
        "levels_count" => 5,
        "side" => "both",
        "enable_orderback" => true,
      },
      "target" => {
        "driver" => "rubykube",
        "host" => "http://www.devkube.com",
        "key" => @authorized_api_key,
        "secret" => SecureRandom.hex,
        "market" => {
          "id" => "ETHUSD",
        },
      },
      "sources" => [
        "driver" => "rubykube",
        "host" => "http://www.devkube.com",
        "key" => @authorized_api_key,
        "secret" => SecureRandom.hex,
        "market" => {
          "id" => "ETHUSD",
          "base" => "ETH",
          "quote" => "USD",
          "min_ask_amount" => "0.01",
          "min_bid_amount" => "0.01",
          "base_precision" => "2",
          "quote_precision" => "8",
        },
      ],
    }
  end


  let(:target) { Arke::Exchange::Rubykube.new(config["target"]) }
  let(:source) { Arke::Exchange::Rubykube.new(config["sources"].first) }

  let(:target_orderbook) { strategy.call }
  before { target.configure_market(config["target"]["market"]) }
  before { source.configure_market(config["sources"].first["market"]) }
  let(:executor) { Arke::ActionExecutor.new(config["id"], target, source) }

  context "Creates an order back on trade event" do
    let(:order) { Arke::Order.new("ethusd", 1.21, 2.14, :buy) }
    let(:order_id) { target.create_order(order).body["id"] }
    let(:trade_executed) { { "trade" => { "ask_id" => order_id, "at" => 1546605232, "bid_id" => order_id, "id" => order_id, "kind" => "ask", "market" => "ethusd", "price" => "1.21", "volume" => "2.14" } } }
    let(:order_back) { Arke::Order.new("ethusd", 1.2221, 2.14, :sell) }

    it "recieves notify_trade" do
      expect(target).to receive(:notify_trade)
      target.send(:process_message, trade_executed)
    end

    it "creates an order back" do
      strategy
      EM.synchrony do
        target.send(:process_message, trade_executed)
        EM::Synchrony.add_timer(0.015) do
          expect(executor.instance_variable_get(:@exchanges)[:rubykube][:queue].instance_variable_get(:@sink).first.params[:order]).to eq(order_back)
          EventMachine.stop
        end
      end
    end
  end

  context "Creates an order back for a partially executed order on trade event" do
    let(:bid_order) { Arke::Order.new("ethusd", 1.21, 2.14, :buy) }
    let(:ask_order) { Arke::Order.new("ethusd", 1.21, 1.05, :sell) }
    let(:bid_order_id) { target.create_order(bid_order).body["id"] }
    let(:ask_order_id) { target.create_order(ask_order).body["id"] }
    let(:trade_executed) { { "trade" => { "ask_id" => ask_order_id, "at" => 1546605232, "bid_id" => bid_order_id, "id" => "123", "kind" => "bid", "market" => "ethusd", "price" => "1.21", "volume" => "1.05" } } }
    let(:buy_order_back) { Arke::Order.new("ethusd", 1.2221, 1.05, :sell) }
    let(:sell_order_back) { Arke::Order.new("ethusd", 0.968, 1.05, :buy) }
    let(:trade_executed_2) { { "trade" => { "ask_id" => "1234321", "at" => 1546605232, "bid_id" => bid_order_id, "id" => "123", "kind" => "bid", "market" => "ethusd", "price" => "1.21", "volume" => "1.05" } } }

    it "receives notify_trade twice" do
      expect(target).to receive(:notify_trade).twice
      target.send(:process_message, trade_executed)
    end

    it "creates two orders back" do
      strategy
      EM.synchrony do
        target.send(:process_message, trade_executed)
        expect(executor.instance_variable_get(:@exchanges)[:rubykube][:queue].instance_variable_get(:@sink).count).to eq 0
        EM::Synchrony.add_timer(0.15) do
          expect(executor.instance_variable_get(:@exchanges)[:rubykube][:queue].instance_variable_get(:@sink).first.params[:order]).to eq(buy_order_back)
          expect(executor.instance_variable_get(:@exchanges)[:rubykube][:queue].instance_variable_get(:@sink).second.params[:order]).to eq(sell_order_back)
          EventMachine.stop
        end
      end
    end

    it "Creates one order back" do
      strategy
      EM.synchrony do
        target.send(:process_message, trade_executed_2)
        expect(executor.instance_variable_get(:@exchanges)[:rubykube][:queue].instance_variable_get(:@sink).count).to eq 0
        EM::Synchrony.add_timer(0.15) do
          expect(executor.instance_variable_get(:@exchanges)[:rubykube][:queue].instance_variable_get(:@sink).first.params[:order]).to eq(buy_order_back)
          EventMachine.stop
        end
      end
    end
  end

  context "group trades" do
    let(:order_1) { Arke::Order.new("ethusd", 23, 0.3, :sell) }
    let(:order_2) { Arke::Order.new("ethusd", 22, 0.9, :sell) }
    let(:order_3) { Arke::Order.new("ethusd", 23, 0.9, :sell) }
    let(:order_4) { Arke::Order.new("ethusd", 23, 1, :buy) }

    it "group 4 trades to 3 orders" do
      trades = []
      trades << [order_1.market, order_1.price, order_1.amount, order_1.side]
      trades << [order_2.market, order_2.price, order_2.amount, order_2.side]
      trades << [order_3.market, order_3.price, order_3.amount, order_3.side]
      trades << [order_4.market, order_4.price, order_4.amount, order_4.side]
      expect(strategy.group_trades(trades)).to eq({[23, :sell]=>["ethusd", 1.2], [22, :sell]=>["ethusd", 0.9], [23, :buy]=>["ethusd", 1]})
    end
  end
end
