require "rails_helper"

describe Arke::ActionExecutor do
  let(:delay) { 0.5 }
  let(:config) do
    {
      "target" => {
        "driver" => "bitfaker",
        "market" => {
          "id" => "ETHUSD",
          "base" => "ETH",
          "quote" => "USD",
          "min_ask_amount" => "0.01",
          "min_bid_amount" => "0.01",
          "base_precision" => 6,
          "quote_precision" => 2,
        },
        "delay" => delay,
      }
    }
  end
  let(:account) do
    Arke::Exchange::Bitfaker.new(
      {
        'delay' => delay,
      }
    )
  end

  let(:target) { Arke::Market.new(config["target"]["market"], account) }
  let(:market) { config["target"]["market"]['id'] }
  let(:sources) { }
  let(:action_executor) { Arke::ActionExecutor.new(config["id"], account) }
  let(:actions) { [] }

  context "actions are empty, delay 1 sec" do
    it "doesn't schedule an action" do
      expect(action_executor).not_to receive(:schedule)
      expect(actions).not_to receive(:shift)
      action_executor.push(actions)
    end
  end

  context "actions aren't empty, no delay" do
    let(:order_buy) { Arke::Order.new(market, 1, 1, :buy) }
    let(:action1) { Arke::Action.new(:order_create, target, { order: order_buy }) }
    let(:actions) { [action1] }
    let(:delay) { 0.0 }

    it "schedules an actions without delay" do
      expect(action_executor.instance_variable_get(:@queue)).to receive(:<<)
      action_executor.push(actions)
      expect(action1.destination.account).to receive(:create_order).with(order_buy)
      action_executor.send(:schedule, action1)
    end
  end

  context "actions aren't empty, delay 0.5 sec" do
    let(:order_buy) { Arke::Order.new(market, 1, 1, :buy) }
    let(:order_sell) { Arke::Order.new(market, 1.1, 1, :sell, "limit", 12) }
    let(:order_sell2) { Arke::Order.new(market, 1.4, 1, :sell) }
    let(:order_buy2) { Arke::Order.new(market, 1.4, 3, :buy, "limit", 42) }
    let(:action1) { Arke::Action.new(:order_create, target, { order: order_buy }) }
    let(:action2) { Arke::Action.new(:order_stop, target, { order:  order_sell }) }
    let(:action3) { Arke::Action.new(:order_stop, target, { order:  order_buy2 }) }
    let(:action4) { Arke::Action.new(:order_create, target, { order: order_sell2 }) }
    let(:actions) { [action1, action2, action3, action4] }

    it "schedules all the actions with delay" do
      expect(action_executor.instance_variable_get(:@queue)).to receive(:<<).exactly(4).times
      action_executor.push(actions)
      expect(target.account).to receive(:create_order).with(order_buy)
      expect(target.account).to receive(:stop_order).with(order_sell)
      expect(target.account).to receive(:stop_order).with(order_buy2)
      expect(target.account).to receive(:create_order).with(order_sell2)
      action_executor.send(:schedule, action1)
      action_executor.send(:schedule, action2)
      action_executor.send(:schedule, action3)
      action_executor.send(:schedule, action4)
    end
  end
end
