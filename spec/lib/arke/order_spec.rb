# frozen_string_literal: true

describe Arke::Order do
  let(:order1) { Arke::Order.new("ethusd", 1, 1, :buy) }
  let(:order2) { Arke::Order.new("ethusd", 1, 1, :buy) }
  let(:order3) { Arke::Order.new("btcusd", 1, 1, :buy) }
  let(:order4) { Arke::Order.new("ethusd", 2, 1, :buy) }
  let(:order5) { Arke::Order.new("ethusd", 1, 2, :buy) }
  let(:order6) { Arke::Order.new("ethusd", 1, 1, :sell) }

  it "supports comparison" do
    expect(order1).to eq(order2)
    expect(order1).to_not eq(order3)
    expect(order1).to_not eq(order4)
    expect(order1).to_not eq(order5)
    expect(order1).to_not eq(order6)
  end

  context "apply_precision" do
    let(:target_config) do
      {
        "id"     => 1,
        "driver" => "bitfaker",
      }
    end
    let(:target_account) { Arke::Exchange.create(target_config) }

    it "applies target market precision for price and amount" do
      order = Arke::Order.new("BTCUSD", 1.123456789, 2.456789123, :buy)
      order.apply_requirements(target_account)
      expect(order.price).to eq(1.123456)
      expect(order.amount).to eq(2.456789)

      order = Arke::Order.new("BTCUSD", 2.456789123, 1.123456789, :buy)
      order.apply_requirements(target_account)
      expect(order.price).to eq(2.456789)
      expect(order.amount).to eq(1.123456)
    end

    it "applies target market minimum order specification" do
      order = Arke::Order.new("BTCUSD", 1.123456789, 0.045678912, :buy)
      order.apply_requirements(target_account)
      expect(order.price).to eq(1.123456)
      expect(order.amount).to eq(0.1)
    end

    it "doesn't change price and amount if the precision is correct" do
      order = Arke::Order.new("BTCUSD", 1.123456, 2.456789, :buy)
      order.apply_requirements(target_account)
      expect(order.price).to eq(1.123456)
      expect(order.amount).to eq(2.456789)

      order = Arke::Order.new("BTCUSD", 2.45, 1.12, :buy)
      order.apply_requirements(target_account)
      expect(order.price).to eq(2.45)
      expect(order.amount).to eq(1.12)
    end
  end
end
