# frozen_string_literal: true

require "rails_helper"

describe Arke::Strategy::Orderback do
  include_context "mocked rubykube"

  let!(:strategy) { Arke::Strategy::Orderback.new([source], target, config, nil) }
  let(:config) do
    {
      "id"      => 1,
      "type"    => "strategy1",
      "params"  => {
        "spread_bids"           => 0.01,
        "spread_asks"           => 0.2,
        "limit_bids"            => 1.0,
        "limit_asks"            => 1.5,
        "levels_algo"           => "constant",
        "levels_size"           => 0.01,
        "levels_count"          => 5,
        "side"                  => "both",
        "enable_orderback"      => true,
        "min_order_back_amount" => 1,
      },
      "target"  => {
        "account_id" => 1,
        "market"     => {
          "id" => "ETHUSD",
        },
      },
      "sources" => [
        "account_id" => 1,
        "market"     => {
          "id"              => "ETHUSD",
          "base"            => "ETH",
          "quote"           => "USD",
          "min_ask_amount"  => "0.01",
          "min_bid_amount"  => "0.01",
          "base_precision"  => "2",
          "quote_precision" => "8",
        },
      ],
    }
  end
  let(:account_config) do
    {
      "id"     => 1,
      "driver" => "rubykube",
      "host"   => "http://www.devkube.com",
      "key"    => @authorized_api_key,
      "secret" => SecureRandom.hex,
    }
  end

  let(:account) { Arke::Exchange::Rubykube.new(account_config) }
  let(:target) { Arke::Market.new(config["target"]["market"], account) }
  let(:source) { Arke::Market.new(config["sources"].first["market"], account) }

  let(:target_orderbook) { strategy.call }
  let(:executor) { Arke::ActionExecutor.new(config["id"], account) }

  context "callback method is functioning" do
    it "registers a callback" do
      expect(target.account.instance_variable_get(:@trades_cb).length).to eq(1)
    end
  end

  context "Creates an order back on trade event" do
    let(:order) { Arke::Order.new("ethusd", 1.21, 2.14, :buy) }
    let(:order_id) { target.account.create_order(order).id}
    let(:order_created) { {"order" => {"id" => order_id, "kind" => "bid", "market" => "ethusd", "price" => "1.21", "remaining_volume" => "2.14", "state" => "wait"}} }
    let(:trade_executed) { {"trade" => {"ask_id" => order_id, "at" => 1_546_605_232, "bid_id" => order_id, "id" => order_id, "kind" => "ask", "market" => "ethusd", "price" => "1.21", "volume" => "2.14"}} }
    let(:low_trade_executed_1) { {"trade" => {"ask_id" => order_id, "at" => 1_546_605_232, "bid_id" => order_id, "id" => 12, "kind" => "ask", "market" => "ethusd", "price" => "1.21", "volume" => "0.14"}} }
    let(:low_trade_executed_2) { {"trade" => {"ask_id" => order_id, "at" => 1_546_605_232, "bid_id" => order_id, "id" => 13, "kind" => "ask", "market" => "ethusd", "price" => "1.21", "volume" => "2"}} }
    let(:order_back) { Arke::Order.new("ETHUSD", 1.2221, 2.14, :sell) }
    before(:each) do
      target.account.executor = executor
      target.account.send(:process_message, order_created)
    end

    it "recieves order" do
      expect(target.open_orders.book[:buy].length).to eq 1
    end

    it "recieves notify_trade" do
      expect(target.account).to receive(:notify_trade).twice
      target.account.send(:process_message, trade_executed)
    end

    it "creates an order back" do
      target.account.send(:process_message, order_created)
      EM.synchrony do
        target.account.send(:process_message, trade_executed)
        EM::Synchrony.add_timer(0.015) do
          expect(executor.instance_variable_get(:@queue).instance_variable_get(:@sink).first.params[:order]).to eq(order_back)
          EventMachine.stop
        end
      end
    end

    it "doesn't create an order back because of low amount" do
      target.account.send(:process_message, order_created)
      EM.synchrony do
        target.account.send(:process_message, low_trade_executed_1)
        EM::Synchrony.add_timer(0.015) do
          expect(executor.instance_variable_get(:@queue).instance_variable_get(:@sink).first).to eq nil
          EventMachine.stop
        end
      end
    end

    it "creates an order back from two executed trades" do
      target.account.send(:process_message, order_created)
      EM.synchrony do
        target.account.send(:process_message, low_trade_executed_1)
        target.account.send(:process_message, low_trade_executed_2)
        EM::Synchrony.add_timer(Arke::Strategy::Orderback::DEFAULT_ORDERBACK_GRACE_TIME + 0.005) do
          expect(executor.instance_variable_get(:@queue).instance_variable_get(:@sink).first.params[:order]).to eq(order_back)
          EventMachine.stop
        end
      end
    end
  end

  context "Creates an order back for a partially executed order on trade event" do
    let(:bid_order) { Arke::Order.new("ethusd", 1.21, 2.14, :buy, "limit", 42) }
    let(:ask_order) { Arke::Order.new("ethusd", 1.21, 1.05, :sell, "limit", 43) }
    let(:bid_order_id) { bid_order.id }
    let(:ask_order_id) { ask_order.id }
    let(:bid_order_created) { {"order" => {"id" => bid_order_id, "kind" => "bid", "market" => "ethusd", "price" => "1.21", "remaining_volume" => "2.14", "state" => "wait"}} }
    let(:ask_order_created) { {"order" => {"id" => ask_order_id, "kind" => "ask", "market" => "ethusd", "price" => "1.21", "remaining_volume" => "1.05", "state" => "wait"}} }
    let(:trade_executed) { {"trade" => {"ask_id" => ask_order_id, "at" => 1_546_605_232, "bid_id" => bid_order_id, "id" => "123", "kind" => "bid", "market" => "ethusd", "price" => "1.21", "volume" => "1.05"}} }
    let(:buy_order_back) { Arke::Order.new("ETHUSD", 1.2221, 1.05, :sell) }
    let(:sell_order_back) { Arke::Order.new("ETHUSD", 0.968, 1.05, :buy) }
    let(:trade_executed_2) { {"trade" => {"ask_id" => "1234321", "at" => 1_546_605_232, "bid_id" => bid_order_id, "id" => "123", "kind" => "bid", "market" => "ethusd", "price" => "1.21", "volume" => "1.05"}} }
    before(:each) { target.account.executor = executor }

    it "receives notify_trade twice" do
      target.account.send(:process_message, bid_order_created)
      target.account.send(:process_message, ask_order_created)
      expect(target.account).to receive(:notify_trade).twice
      target.account.send(:process_message, trade_executed)
    end

    it "creates two orders back" do
      target.account.send(:process_message, bid_order_created)
      target.account.send(:process_message, ask_order_created)
      EM.synchrony do
        target.account.send(:process_message, trade_executed)
        expect(executor.instance_variable_get(:@queue).instance_variable_get(:@sink).count).to eq 0
        EM::Synchrony.add_timer(0.15) do
          expect(executor.instance_variable_get(:@queue).instance_variable_get(:@sink).count).to eq 2
          expect(executor.instance_variable_get(:@queue).instance_variable_get(:@sink).first.params[:order]).to eq(buy_order_back)
          expect(executor.instance_variable_get(:@queue).instance_variable_get(:@sink).second.params[:order]).to eq(sell_order_back)
          EventMachine.stop
        end
      end
    end

    it "Creates one order back" do
      target.account.send(:process_message, bid_order_created)
      target.account.send(:process_message, ask_order_created)
      EM.synchrony do
        target.account.send(:process_message, trade_executed_2)
        expect(executor.instance_variable_get(:@queue).instance_variable_get(:@sink).count).to eq 0
        EM::Synchrony.add_timer(0.15) do
          expect(executor.instance_variable_get(:@queue).instance_variable_get(:@sink).count).to eq(1)
          expect(executor.instance_variable_get(:@queue).instance_variable_get(:@sink).first.params[:order]).to eq(buy_order_back)
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

    it "groups trades by price and side" do
      trades = {
        10 => {1 => [order_1.market, order_1.price, order_1.amount, order_1.side]},
        11 => {2 => [order_2.market, order_2.price, order_2.amount, order_2.side]},
        12 => {3 => [order_3.market, order_3.price, order_3.amount, order_3.side]},
        13 => {4 => [order_4.market, order_4.price, order_4.amount, order_4.side]},
      }

      expect(strategy.group_trades(trades)).to eq(
        [23, :sell] => 1.2,
        [22, :sell] => 0.9,
        [23, :buy]  => 1.0
      )
    end
  end
end
