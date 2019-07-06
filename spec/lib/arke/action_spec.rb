require 'rails_helper'

describe Arke::Action do
  let(:type)   { :create_order }
  let(:dest)   { :bitfaker }
  let(:params) { { order: Arke::Order.new('ethusd', 1, 1, :buy) } }
  let(:params_clone) { { order: Arke::Order.new('ethusd', 1, 1, :buy) } }

  it 'creates instruction' do
    action = Arke::Action.new(type, dest, params)

    expect(action.type).to eq(type)
    expect(action.params).to eq(params)
    expect(action.destination).to eq(dest)
  end

  it 'support comparison' do
    action1 = Arke::Action.new(type, dest, params)
    action2 = Arke::Action.new(type, dest, params_clone)
    expect(action1).to eq(action2)
  end
end
