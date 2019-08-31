require "rails_helper"

describe Arke::Strategy::Microtrades do
  let(:reactor) { double(:reactor) }
  let(:strategy) { Arke::Strategy::Microtrades.new([], target, config, nil, reactor) }
  let(:target) { Arke::Exchange.create(config["target"]) }
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

  let(:config) do
    {
      "type" => "microtrades",
      "params" => {
        "linked_strategy_id" => linked_strategy_id,
        "min_amount" => 0.05,
        "max_amount" => 1,
        "min_price" => min_price,
        "max_price" => max_price,
        "price_difference" => 0.05
      },
      "target" => {
        "driver" => "bitfaker",
        "market" => {
          "id" => "BTCUSD",
          "base" => "BTC",
          "quote" => "USD",
          "base_precision" => 4,
          "quote_precision" => 4,
        },
      }
    }
  end

  let(:target_config) do
    {
      "driver" => "rubykube",
      "host" => "http://www.example.com",
      "key" => nil,
      "secret" => nil,
    }
  end

  let(:target_orderbook) { strategy.call }
  let(:target_bids) { target_orderbook[:buy] }
  let(:target_asks) { target_orderbook[:sell] }

  before(:each) do
    target.fetch_balances
    target.configure_market(config["target"]["market"])
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

  context "strategy is linked to an other" do
    let(:source) { Arke::Exchange.create(config["target"]) }
    let(:linked_strategy_id) { 12 }
    let(:linked_strategy) { Arke::Strategy::Base.new([source], target, config, nil, reactor) }

    it "uses orderbook of linked strategy to define the price of sell and buy orders" do
      expect(reactor).to receive(:find_strategy).with(linked_strategy_id).exactly(:twice).and_return(linked_strategy)
      linked_strategy.source.update_orderbook
      expect(strategy.get_price(:buy)).to eq(145.8030)
      expect(strategy.get_price(:sell)).to eq(131.8410)
    end

    it "raise an error if the orderbook is empty" do
      expect(reactor).to receive(:find_strategy).with(linked_strategy_id).exactly(:twice).and_return(linked_strategy)
      expect{strategy.get_price(:buy)}.to raise_error(Arke::Strategy::Microtrades::EmptyOrderBook)
      expect{strategy.get_price(:sell)}.to raise_error(Arke::Strategy::Microtrades::EmptyOrderBook)
    end
  end
end
