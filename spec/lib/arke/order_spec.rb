require 'rails_helper'

describe Arke::Order do
  let(:order1) { Arke::Order.new('ethusd', 1, 1, :buy) }
  let(:order2) { Arke::Order.new('ethusd', 1, 1, :buy) }
  let(:order3) { Arke::Order.new('btcusd', 1, 1, :buy) }
  let(:order4) { Arke::Order.new('ethusd', 2, 1, :buy) }
  let(:order5) { Arke::Order.new('ethusd', 1, 2, :buy) }
  let(:order6) { Arke::Order.new('ethusd', 1, 1, :sell) }

  it 'supports comparison' do
    expect(order1).to eq(order2)
    expect(order1).to_not eq(order3)
    expect(order1).to_not eq(order4)
    expect(order1).to_not eq(order5)
    expect(order1).to_not eq(order6)
  end
end
