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
        },
        "delay" => delay,
      }
    }
  end
  let(:action_executor) { Arke::ActionExecutor.new(config) }
  let(:target) { Arke::Exchange.create(config["target"]) }
  let(:market) { config["target"]["market"]['id'] }
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
      expect(action_executor).to receive(:clear_queue)
      expect(action_executor.exchanges[target.driver.to_sym][:queue]).to receive(:<<)
      action_executor.push(actions)
      expect(action1.destination).to receive(:create_order).with(order_buy)
      action_executor.send(:schedule, action1)
    end
  end

  context "actions aren't empty, delay 0.5 sec" do
    let(:order_buy) { Arke::Order.new(market, 1, 1, :buy) }
    let(:order_sell) { Arke::Order.new(market, 1.1, 1, :sell) }
    let(:order_sell2) { Arke::Order.new(market, 1.4, 1, :sell) }
    let(:order_buy2) { Arke::Order.new(market, 1.4, 3, :buy) }
    let(:action1) { Arke::Action.new(:order_create, target, { order: order_buy }) }
    let(:action2) { Arke::Action.new(:order_stop, target, { id: 12 }) }
    let(:action3) { Arke::Action.new(:order_stop, target, { id: "42" }) }
    let(:action4) { Arke::Action.new(:order_create, target, { order: order_sell2 }) }
    let(:actions) { [action1, action2, action3, action4] }

    it "schedules all the actions with delay" do
      expect(action_executor).to receive(:clear_queue)
      expect(action_executor.exchanges[target.driver.to_sym][:queue]).to receive(:<<).exactly(4).times
      action_executor.push(actions)
      expect(target).to receive(:create_order).with(order_buy)
      expect(target).to receive(:stop_order).with(12)
      expect(target).to receive(:stop_order).with("42")
      expect(target).to receive(:create_order).with(order_sell2)
      action_executor.send(:schedule, action1)
      action_executor.send(:schedule, action2)
      action_executor.send(:schedule, action3)
      action_executor.send(:schedule, action4)
    end
  end
end
