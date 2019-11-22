# frozen_string_literal: true

describe Arke::ActionExecutor do
  let(:delay) { 0.5 }
  let(:config) do
    {
      "target" => {
        "driver" => "bitfaker",
        "market" => {
          "id"              => "ETHUSD",
          "base"            => "ETH",
          "quote"           => "USD",
          "min_ask_amount"  => "0.01",
          "min_bid_amount"  => "0.01",
          "base_precision"  => 6,
          "quote_precision" => 2,
        },
        "delay"  => delay,
      }
    }
  end
  let(:account) do
    Arke::Exchange::Bitfaker.new(
      "delay" => delay
    )
  end

  let(:target) { Arke::Market.new(config["target"]["market"], account) }
  let(:market) { config["target"]["market"]["id"] }
  let(:sources) {}
  let!(:action_executor) { Arke::ActionExecutor.new(account) }
  let(:actions) { [] }

  context "actions aren't empty, no delay" do
    let(:order_buy) { Arke::Order.new(market, 1, 1, :buy) }
    let(:action1) { Arke::Action.new(:order_create, target, order: order_buy) }
    let(:actions) { [action1] }
    let(:delay) { 0.0 }

    it "schedules an actions without delay" do
      expect(account).to receive(:create_order).with(order_buy)
      action_executor.send(:schedule, action1)
    end
  end

  context "actions aren't empty, delay 0.5 sec" do
    let(:order_buy) { Arke::Order.new(market, 1, 1, :buy) }
    let(:order_sell) { Arke::Order.new(market, 1.1, 1, :sell, "limit", 12) }
    let(:order_sell2) { Arke::Order.new(market, 1.4, 1, :sell) }
    let(:order_buy2) { Arke::Order.new(market, 1.4, 3, :buy, "limit", 42) }
    let(:action1) { Arke::Action.new(:order_create, target, order: order_buy) }
    let(:action2) { Arke::Action.new(:order_stop, target, order:  order_sell) }
    let(:action3) { Arke::Action.new(:order_stop, target, order:  order_buy2) }
    let(:action4) { Arke::Action.new(:order_create, target, order: order_sell2) }
    let(:actions) { [action1, action2, action3, action4] }
    let(:delay) { 0.01 }

    it "trigger actions" do
      expect(account).to receive(:create_order).with(order_buy)
      expect(account).to receive(:stop_order).with(order_sell)
      expect(account).to receive(:stop_order).with(order_buy2)
      expect(account).to receive(:create_order).with(order_sell2)
      action_executor.send(:schedule, action1)
      action_executor.send(:schedule, action2)
      action_executor.send(:schedule, action3)
      action_executor.send(:schedule, action4)
    end

    it "schedules all the actions with delay" do
      action_executor.create_queue("ABCXYZ")
      action_executor.push("ABCXYZ", actions)
      expect(account).to receive(:create_order).with(order_buy)
      expect(account).to receive(:stop_order).with(order_sell)
      expect(account).to receive(:stop_order).with(order_buy2)
      expect(account).to receive(:create_order).with(order_sell2)
      EM.synchrony do
        action_executor.start
        EM::Synchrony.add_timer(0.05) { EM.stop }
      end
    end
  end

  context "start" do
    let(:queue_ids) { %w[a b c] }
    let(:block) { double(call: nil) }
    let(:delay) { 3 }

    before(:each) do
      queue_ids.each do |queue_id|
        action_executor.create_queue(queue_id)
      end
    end

    it "applies offsets to timers to spread API calls over time" do
      expect(block).to receive(:call).with("a", 0.5, 1.0)
      expect(block).to receive(:call).with("b", 1.5, 1.0)
      expect(block).to receive(:call).with("c", 2.5, 1.0)
      action_executor.start(&block.method(:call))
    end

    context "one strategy" do
      let(:queue_ids) { %w[a] }
      it "works with one strategy" do
        expect(block).to receive(:call).with("a", 1.5, 3.0)
        action_executor.start(&block.method(:call))
      end
    end

    context "zero strategy" do
      let(:queue_ids) { %w[] }
      it "works with one strategy" do
        action_executor.start(&block.method(:call))
      end
    end
  end
end
