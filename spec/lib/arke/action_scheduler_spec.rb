require "rails_helper"

describe Arke::ActionScheduler do
  let(:market) { "ethusd" }
  let(:exchange_config) do
    {
      "driver" => "rubykube",
      "host" => "http://www.example.com",
      'market' => {
        "id" => "ETHUSDT",
        "base" => "ETH",
        "quote" => "USDT",
      },
    }
  end
  let(:current_openorders) { Arke::Orderbook::OpenOrders.new(market) }
  let(:desired_orderbook) { Arke::Orderbook::Orderbook.new(market) }
  let(:target) { Arke::Exchange.create(exchange_config) }
  let(:action_scheduler) { Arke::ActionScheduler.new(current_openorders, desired_orderbook, target) }
  let(:order_buy) { Arke::Order.new(market, 1, 1, :buy) }
  let(:order_sell) { Arke::Order.new(market, 1.1, 1, :sell) }
  let(:order_sell2) { Arke::Order.new(market, 1.4, 1, :sell) }
  let(:order_buy2) { Arke::Order.new(market, 1.4, 3, :buy) }

  context "current and desired orderbooks are empty" do
    it "creates no action" do
      action_scheduler.schedule
      expect(action_scheduler.actions).to be_empty()
    end
  end

  context "desired orderbook is empty" do
    it "generates stop order action for order buy" do
      current_openorders.add_order(order_buy, 10)
      expect(action_scheduler.schedule).to eq([
        Arke::Action.new(:order_stop, target, { id: 10, order: order_buy }),
      ])
    end

    it "generates two more actions for more orders" do
      current_openorders.add_order(order_sell, 10)
      current_openorders.add_order(order_sell2, 11)
      current_openorders.add_order(order_buy2, 12)
      expect(action_scheduler.schedule).to eq([
        Arke::Action.new(:order_stop, target, { id: 12, order: order_buy2 }),
        Arke::Action.new(:order_stop, target, { id: 10, order: order_sell }),
        Arke::Action.new(:order_stop, target, { id: 11, order: order_sell2 }),
      ])
    end
  end

  context "current orderbook is empty" do
    it "generates order creation" do
      desired_orderbook.update(order_buy)
      desired_orderbook.update(order_sell)
      action_scheduler.schedule
      expect(action_scheduler.actions).to eq([
        Arke::Action.new(:order_create, target, { order: order_buy }),
        Arke::Action.new(:order_create, target, { order: order_sell }),
      ])
    end
  end

  context "current and desired orderbooks aren't empty" do
    it "creates needed orders" do
      desired_orderbook.update(order_buy)
      desired_orderbook.update(order_sell)
      desired_orderbook.update(order_sell2)
      desired_orderbook.update(order_buy2)
      current_openorders.add_order(order_buy, 10)
      current_openorders.add_order(order_sell, 11)
      expect(action_scheduler.schedule).to eq([
        Arke::Action.new(:order_create, target, { order: order_buy2 }),
        Arke::Action.new(:order_create, target, { order: order_sell2 }),
      ])
    end

    it "stops created order" do
      desired_orderbook.update(order_buy)
      desired_orderbook.update(order_sell)
      current_openorders.add_order(order_sell2, 10)
      current_openorders.add_order(order_buy2, 11)
      current_openorders.add_order(order_buy, 12)
      current_openorders.add_order(order_sell, 13)
      expect(action_scheduler.schedule).to eq([
        Arke::Action.new(:order_stop, target, { id: 11, order: order_buy2 }),
        Arke::Action.new(:order_stop, target, { id: 10, order: order_sell2 }),
      ])
    end

    it "stops some orders first to free funds and creates orders asap" do
      order_buy_10 = Arke::Order.new(market, 1.4, 3, :buy)
      order_buy_11 = Arke::Order.new(market, 1, 1, :buy)
      order_buy_12 = Arke::Order.new(market, 0.9, 1, :buy)
      order_sell_13 = Arke::Order.new(market, 1.1, 1, :sell)
      order_sell_14 = Arke::Order.new(market, 1.2, 1, :sell)

      current_openorders.add_order(order_buy_10, 10)
      current_openorders.add_order(order_buy_11, 11)
      current_openorders.add_order(order_buy_12, 12)
      current_openorders.add_order(order_sell_13, 13)
      current_openorders.add_order(order_sell_14, 14)

      desired_orderbook.update(Arke::Order.new(market, 1, 1, :buy))
      desired_orderbook.update(Arke::Order.new(market, 1.1, 1, :buy))
      desired_orderbook.update(Arke::Order.new(market, 0.9, 1.5, :buy))
      desired_orderbook.update(Arke::Order.new(market, 1.1, 1, :sell))
      desired_orderbook.update(Arke::Order.new(market, 1.4, 1, :sell))

      expect(action_scheduler.schedule).to eq([
        Arke::Action.new(:order_stop, target, { id: 10, order: order_buy_10 }), # buy amount: 3
        Arke::Action.new(:order_create, target, { order: Arke::Order.new(market, 1.1, 1, :buy) }),
        Arke::Action.new(:order_create, target, { order: Arke::Order.new(market, 0.9, 1.5, :buy) }),
        Arke::Action.new(:order_stop, target, { id: 12, order: order_buy_12 }), # buy amount: 1
        Arke::Action.new(:order_stop, target, { id: 14, order: order_sell_14 }), # sell amount: 1
        Arke::Action.new(:order_create, target, { order: Arke::Order.new(market, 1.4, 1, :sell) }),
      ])
    end
  end
end
