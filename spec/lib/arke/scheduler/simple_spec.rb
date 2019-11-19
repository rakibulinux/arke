# frozen_string_literal: true

require "rails_helper"

describe Arke::Scheduler::Simple do
  let(:market) { "ethusd" }
  let(:exchange_config) do
    {
      "driver" => "rubykube",
      "host"   => "http://www.example.com",
      "market" => {
        "id"              => "ETHUSDT",
        "base"            => "ETH",
        "quote"           => "USDT",
        "base_precision"  => 4,
        "quote_precision" => 4,
        "min_ask_amount"  => 0.01,
        "min_bid_amount"  => 0.01,
      },
    }
  end
  let(:current_openorders) { Arke::Orderbook::OpenOrders.new(market) }
  let(:desired_orderbook) { Arke::Orderbook::Orderbook.new(market) }
  let(:target) { Arke::Market.new(exchange_config["market"], Arke::Exchange::Bitfaker.new(exchange_config)) }
  let(:action_scheduler) { Arke::Scheduler::Simple.new(current_openorders, desired_orderbook, target) }
  let(:order_buy) { Arke::Order.new(market, 1, 1, :buy, "limit", 9) }
  let(:order_sell) { Arke::Order.new(market, 1.1, 1, :sell, "limit", 10) }
  let(:order_sell2) { Arke::Order.new(market, 1.4, 1, :sell, "limit", 11) }
  let(:order_buy2) { Arke::Order.new(market, 0.9, 3, :buy, "limit", 12) }

  context "current and desired orderbooks are empty" do
    it "creates no action" do
      action_scheduler.schedule
      expect(action_scheduler.actions).to be_empty()
    end
  end

  context "desired orderbook is empty" do
    it "generates stop order action for order buy" do
      current_openorders.add_order(order_buy)
      expect(action_scheduler.schedule).to \
        eq([
             Arke::Action.new(:order_stop, target, id: 9, order: order_buy),
           ])
    end

    it "generates two more actions for more orders" do
      current_openorders.add_order(order_sell)
      current_openorders.add_order(order_sell2)
      current_openorders.add_order(order_buy2)
      expect(action_scheduler.schedule).to \
        eq([
             Arke::Action.new(:order_stop, target, id: 10, order: order_sell),
             Arke::Action.new(:order_stop, target, id: 11, order: order_sell2),
             Arke::Action.new(:order_stop, target, id: 12, order: order_buy2),
           ])
    end
  end

  context "current orderbook is empty" do
    it "generates order creation" do
      desired_orderbook.update(order_buy)
      desired_orderbook.update(order_sell)
      action_scheduler.schedule
      expect(action_scheduler.actions).to \
        eq([
             Arke::Action.new(:order_create, target, order: order_sell),
             Arke::Action.new(:order_create, target, order: order_buy),
           ])
    end
  end

  context "current and desired orderbooks aren't empty" do
    it "creates needed orders" do
      current_openorders.add_order(order_buy)
      current_openorders.add_order(order_sell)

      desired_orderbook.update(order_buy)
      desired_orderbook.update(order_sell)
      desired_orderbook.update(order_sell2)
      desired_orderbook.update(order_buy2)

      expect(action_scheduler.schedule).to \
        eq([
             Arke::Action.new(:order_stop,   target, order: order_buy, id: order_buy.id),
             Arke::Action.new(:order_create, target, order: order_buy),
             Arke::Action.new(:order_create, target, order: order_buy2),
             Arke::Action.new(:order_stop,   target, order: order_sell, id: order_sell.id),
             Arke::Action.new(:order_create, target, order: order_sell),
             Arke::Action.new(:order_create, target, order: order_sell2),
           ])
    end

    it "stops created order" do
      current_openorders.add_order(order_sell2)
      current_openorders.add_order(order_buy2)
      expect(action_scheduler.schedule).to \
        eq([
             Arke::Action.new(:order_stop, target, id: 11, order: order_sell2),
             Arke::Action.new(:order_stop, target, id: 12, order: order_buy2),
           ])
    end

    it "stops some orders first to free funds and creates orders asap" do
      order_sell_14 = Arke::Order.new(market, 2.0, 1, :sell, "limit", 14)
      order_sell_13 = Arke::Order.new(market, 1.9, 1, :sell, "limit", 13)
      order_buy_10  = Arke::Order.new(market, 1.4, 3, :buy,  "limit", 10)
      order_buy_11  = Arke::Order.new(market, 1,   1, :buy,  "limit", 11)
      order_buy_12  = Arke::Order.new(market, 0.9, 1, :buy,  "limit", 12)

      current_openorders.add_order(order_buy_10)
      current_openorders.add_order(order_buy_11)
      current_openorders.add_order(order_buy_12)
      current_openorders.add_order(order_sell_13)
      current_openorders.add_order(order_sell_14)

      desired_orderbook.update(Arke::Order.new(market, 1.91, 1,  :sell))
      desired_orderbook.update(Arke::Order.new(market, 1.41, 1,  :sell))
      desired_orderbook.update(Arke::Order.new(market, 1.1,  1,  :buy))
      desired_orderbook.update(Arke::Order.new(market, 1.01, 1,  :buy))
      desired_orderbook.update(Arke::Order.new(market, 0.9,  1.5, :buy))
      pp actions = action_scheduler.schedule

      expect(actions).to \
        eq([
             Arke::Action.new(:order_stop, target, id: 10, order: order_buy_10), # buy amount: 3
             Arke::Action.new(:order_create, target, order: Arke::Order.new(market, 1.1, 1, :buy)),
             Arke::Action.new(:order_create, target, order: Arke::Order.new(market, 1.01, 1, :buy)),
             Arke::Action.new(:order_stop, target, id: 11, order: order_buy_11), # buy amount: 1
             Arke::Action.new(:order_create, target, order: Arke::Order.new(market, 0.9, 1.5, :buy)),
             Arke::Action.new(:order_stop, target, id: 12, order: order_buy_12), # buy amount: 1

             Arke::Action.new(:order_stop, target, id: 13, order: order_sell_13), # sell amount: 1
             Arke::Action.new(:order_create, target, order: Arke::Order.new(market, 1.41, 1, :sell)),
             Arke::Action.new(:order_stop, target, id: 14, order: order_sell_14), # sell amount: 1
             Arke::Action.new(:order_create, target, order: Arke::Order.new(market, 1.91, 1, :sell)),
           ])
    end

    it "stops overlapping orders first (sell overlap buy on market price DUMP)" do
      order_sell = Arke::Order.new(market, 2.0, 1, :sell, "limit", 1)
      order_buy  = Arke::Order.new(market, 1.0, 1, :buy,  "limit", 2)

      current_openorders.add_order(order_buy)
      current_openorders.add_order(order_sell)

      desired_orderbook.update(Arke::Order.new(market, 2.2, 1, :sell))
      desired_orderbook.update(Arke::Order.new(market, 2.1, 1, :buy))
      actions = action_scheduler.schedule

      expect(actions).to \
        eq([
             Arke::Action.new(:order_stop, target, id: 1, order: order_sell),
             Arke::Action.new(:order_create, target, order: Arke::Order.new(market, 2.2, 1, :sell)),

             Arke::Action.new(:order_stop, target, id: 2, order: order_buy),
             Arke::Action.new(:order_create, target, order: Arke::Order.new(market, 2.1, 1, :buy)),
           ])
    end

    it "stops overlapping orders first (buy overlap sell on market price PUMP)" do
      order_sell_14 = Arke::Order.new(market, 2.0,  1, :sell, "limit", 14)
      order_sell_13 = Arke::Order.new(market, 1.9,  1, :sell, "limit", 13)
      order_buy_10  = Arke::Order.new(market, 1.4,  3, :buy,  "limit", 10)
      order_buy_11  = Arke::Order.new(market, 1.35, 1, :buy,  "limit", 11)

      current_openorders.add_order(order_buy_10)
      current_openorders.add_order(order_buy_11)
      current_openorders.add_order(order_sell_13)
      current_openorders.add_order(order_sell_14)

      desired_orderbook.update(Arke::Order.new(market, 2.2, 1,  :sell))
      desired_orderbook.update(Arke::Order.new(market, 2.1, 1,  :sell))
      desired_orderbook.update(Arke::Order.new(market, 2.0, 1,  :buy))
      desired_orderbook.update(Arke::Order.new(market, 1.9, 1,  :buy))
      actions = action_scheduler.schedule

      expect(actions).to \
        eq([
             Arke::Action.new(:order_stop, target, id: 13, order: order_sell_13),
             Arke::Action.new(:order_create, target, order: Arke::Order.new(market, 2.1, 1, :sell)),
             Arke::Action.new(:order_stop, target, id: 14, order: order_sell_14),
             Arke::Action.new(:order_create, target, order: Arke::Order.new(market, 2.2, 1, :sell)),

             Arke::Action.new(:order_stop, target, id: 10, order: order_buy_10),
             Arke::Action.new(:order_create, target, order: Arke::Order.new(market, 2.0, 1, :buy)),
             Arke::Action.new(:order_create, target, order: Arke::Order.new(market, 1.9, 1, :buy)),
             Arke::Action.new(:order_stop, target, id: 11, order: order_buy_11),
           ])
    end

    it "stops overlapping orders first (buy == sell on market price PUMP)" do
      order_sell = Arke::Order.new(market, 2.0, 1, :sell, "limit", 1)
      order_buy  = Arke::Order.new(market, 1.0, 1, :buy,  "limit", 2)

      current_openorders.add_order(order_buy)
      current_openorders.add_order(order_sell)

      desired_orderbook.update(Arke::Order.new(market, 2.1, 1, :sell))
      desired_orderbook.update(Arke::Order.new(market, 2.0, 1, :buy))
      actions = action_scheduler.schedule

      expect(actions).to \
        eq([
             Arke::Action.new(:order_stop, target, id: 1, order: order_sell),
             Arke::Action.new(:order_create, target, order: Arke::Order.new(market, 2.1, 1, :sell)),

             Arke::Action.new(:order_stop, target, id: 2, order: order_buy),
             Arke::Action.new(:order_create, target, order: Arke::Order.new(market, 2.0, 1, :buy)),
           ])
    end

    it "stops overlapping orders first (buy == sell on market price DUMP)" do
      order_sell = Arke::Order.new(market, 2.0, 1, :sell, "limit", 1)
      order_buy  = Arke::Order.new(market, 1.0, 1, :buy,  "limit", 2)

      current_openorders.add_order(order_buy)
      current_openorders.add_order(order_sell)

      desired_orderbook.update(Arke::Order.new(market, 1.0, 1, :sell))
      desired_orderbook.update(Arke::Order.new(market, 0.9, 1, :buy))
      actions = action_scheduler.schedule

      expect(actions).to \
        eq([
             Arke::Action.new(:order_stop, target, id: 2, order: order_buy),
             Arke::Action.new(:order_create, target, order: Arke::Order.new(market, 0.9, 1, :buy)),

             Arke::Action.new(:order_stop, target, id: 1, order: order_sell),
             Arke::Action.new(:order_create, target, order: Arke::Order.new(market, 1.0, 1, :sell)),

           ])
    end

    it "raises error if any ask price is lower than big price" do
      desired_orderbook.update(Arke::Order.new(market, 2.2, 1,  :sell))
      desired_orderbook.update(Arke::Order.new(market, 2.0, 1,  :sell))
      desired_orderbook.update(Arke::Order.new(market, 2.1, 1,  :buy))
      desired_orderbook.update(Arke::Order.new(market, 1.9, 1,  :buy))
      expect { action_scheduler.schedule }.to raise_error(Arke::Scheduler::InvalidOrderBook)
    end
  end
end
