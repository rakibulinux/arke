# frozen_string_literal: true

require "rails_helper"

describe Arke::Strategy::Microtrades do
  let(:reactor) { double(:reactor) }
  let(:strategy) { Arke::Strategy::Microtrades.new([], target, config, reactor) }
  let(:account) { Arke::Exchange.create(account_config) }
  let(:target_mode) { Arke::Helpers::Flags::DEFAULT_TARGET_FLAGS }
  let(:source_mode) { Arke::Helpers::Flags::DEFAULT_SOURCE_FLAGS }
  let(:target) { Arke::Market.new(config["target"]["market_id"], account, target_mode) }
  let(:price) { 123 }
  let(:random_delta) { 0 }
  let(:side) { "both" }
  let(:spread_asks) { 0.01 }
  let(:spread_bids) { 0.02 }
  let(:limit_asks_base) { 1.0 }
  let(:limit_bids_base) { 1.5 }
  let(:linked_strategy_id) { nil }
  let(:min_price) { 100 }
  let(:max_price) { 100 }
  let(:min_amount) { 350 }
  let(:max_amount) { 400 }

  let(:account_config) do
    {
      "id"     => 1,
      "driver" => "bitfaker",
    }
  end
  let(:side) { "both" }
  let(:config) do
    {
      "type"   => "microtrades",
      "params" => {
        "linked_strategy_id" => linked_strategy_id,
        "min_amount"         => min_amount,
        "max_amount"         => max_amount,
        "min_price"          => min_price,
        "max_price"          => max_price,
        "price_difference"   => 0.05,
        "side"               => side,
      },
      "target" => {
        "driver"    => "bitfaker",
        "market_id" => "BTCUSD",
      }
    }
  end

  let(:target_config) do
    {
      "driver" => "rubykube",
      "host"   => "http://www.example.com",
      "key"    => nil,
      "secret" => nil,
    }
  end

  let(:target_orderbook) { strategy.call }
  let(:target_bids) { target_orderbook[:buy] }
  let(:target_asks) { target_orderbook[:sell] }

  before(:each) do
    target.account.fetch_balances
  end

  context "strategy not linked to an other" do
    it "uses price_min and price_max to define the price of sell and buy orders" do
      expect(strategy.get_price(:buy)).to eq(max_price)
      expect(strategy.get_price(:sell)).to eq(min_price)
    end

    it "delays the first execution" do
      expect(strategy.delay_the_first_execute).to eq(true)
    end
  end

  context "strategy execution" do
    let(:source) { Arke::Market.new(config["target"]["market_id"], account, source_mode) }
    let(:linked_strategy_id) { 12 }
    let(:linked_strategy) { Arke::Strategy::Base.new([source], target, config, reactor) }
    let(:min_amount) { 250 }
    let(:max_amount) { 250 }

    context "on bids side" do
      let(:side) { "bids" }

      it "creates a buy order on the target" do
        expect(reactor).to receive(:find_strategy).with(linked_strategy_id).exactly(:twice).and_return(linked_strategy)
        linked_strategy.target.start

        expect(target.account).to receive(:create_order).with(::Arke::Order.new("BTCUSD", 145.803, 250, :buy, "limit"))
        expect(target.account).to receive(:stop_order).once

        EM.synchrony do
          strategy.call
          EM::Synchrony.add_timer(0.2) { EM.stop }
        end
      end
    end

    context "on asks side" do
      let(:side) { "asks" }

      it "creates a buy order on the target" do
        expect(reactor).to receive(:find_strategy).with(linked_strategy_id).exactly(:twice).and_return(linked_strategy)
        linked_strategy.target.start

        expect(target.account).to receive(:create_order).with(::Arke::Order.new("BTCUSD", 131.841, 171.339326, :sell, "limit"))
        expect(target.account).to receive(:stop_order).once

        EM.synchrony do
          strategy.call
          EM::Synchrony.add_timer(0.2) { EM.stop }
        end
      end
    end
  end

  context "strategy is linked to an other" do
    let(:source) { Arke::Market.new(config["target"]["market_id"], account, source_mode) }
    let(:linked_strategy_id) { 12 }
    let(:linked_strategy) { Arke::Strategy::Base.new([source], target, config, reactor) }

    it "uses orderbook of linked strategy to define the price of sell and buy orders" do
      expect(reactor).to receive(:find_strategy).with(linked_strategy_id).exactly(:twice).and_return(linked_strategy)
      linked_strategy.target.start

      expect(strategy.get_price(:buy)).to eq(145.8030)
      expect(strategy.get_price(:sell)).to eq(131.8410)
    end

    it "limits the amount of sell and buy orders to 60% of linked strategy open orders total supply" do
      expect(reactor).to receive(:find_strategy).with(linked_strategy_id).exactly(:twice).and_return(linked_strategy)
      expect(strategy).to receive(:rand).exactly(:twice).and_return(600)
      linked_strategy.target.start

      expect(linked_strategy.target.open_orders.total_side_amount(:buy)).to eq(285.56554348.to_d)
      expect(linked_strategy.target.open_orders.total_side_amount(:sell)).to eq(700.37113197.to_d)

      expect(strategy.get_amount(:buy)).to eq 420.222679
      expect(strategy.get_amount(:sell)).to eq 171.339326
    end

    it "does not limit the amount of sell and buy orders when it doesn't exceed 60% of linked strategy open orders total supply" do
      expect(reactor).to receive(:find_strategy).with(linked_strategy_id).exactly(:twice).and_return(linked_strategy)
      expect(strategy).to receive(:rand).exactly(:twice).and_return(100)
      linked_strategy.target.start

      expect(linked_strategy.target.open_orders.total_side_amount(:buy)).to eq(285.56554348.to_d)
      expect(linked_strategy.target.open_orders.total_side_amount(:sell)).to eq(700.37113197.to_d)

      expect(strategy.get_amount(:buy)).to eq 100
      expect(strategy.get_amount(:sell)).to eq 100
    end

    it "raise an error if the orderbook is empty" do
      expect(reactor).to receive(:find_strategy).with(linked_strategy_id).exactly(:twice).and_return(linked_strategy)
      expect { strategy.get_price(:buy) }.to raise_error(Arke::Strategy::Microtrades::EmptyOrderBook)
      expect { strategy.get_price(:sell) }.to raise_error(Arke::Strategy::Microtrades::EmptyOrderBook)
    end
  end
end
