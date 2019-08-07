describe Arke::Orderbook::OpenOrders do
  let(:market) { "ethusd" }
  let(:open_orders) { Arke::Orderbook::OpenOrders.new(market) }
  let(:delete_order) { Arke::Order.new(market, 100, 30, :buy, "limit", 1) }
  let(:skip_order) { Arke::Order.new(market, 200, 20, :sell, "limit", 2) }
  let(:create_order) { Arke::Order.new(market, 250, 20, :sell, "limit", 3) }
  let(:update_order) { Arke::Order.new(market, 500, 10, :buy, "limit", 4) }
  let(:update_order_ob) { Arke::Order.new(market, 500, 5, :buy, "limit", 5) }

  let(:orderbook) do
    orderbook = Arke::Orderbook::Orderbook.new(market)

    orderbook.update(skip_order)
    orderbook.update(create_order)
    orderbook.update(update_order_ob)

    orderbook
  end

  it "#contains?" do
    order = skip_order
    open_orders.add_order(order)

    expect(open_orders.contains?(order.side, order.price)).to eq(true)
    expect(open_orders.contains?(order.side, order.price + 100)).to eq(false)
  end

  it "#remove_order" do
    order = skip_order
    open_orders.add_order(order)
    expect(open_orders.contains?(order.side, order.price)).to eq(true)
    open_orders.remove_order(skip_order.id)
    expect(open_orders.contains?(order.side, order.price)).to eq(false)
    expect(open_orders[order.side].size).to eq(0)
  end

  it "#price_amount" do
    skip_order2 = skip_order.clone
    skip_order2.id = 32

    open_orders.add_order(skip_order)
    open_orders.add_order(skip_order2)

    expect(open_orders.price_amount(skip_order.side, skip_order.price)).to eq(2 * skip_order.amount)
  end

  context "open_orders#get_diff" do
    it "return correct diff" do
      open_orders.add_order(delete_order)
      open_orders.add_order(update_order)
      open_orders.add_order(skip_order)

      diff = open_orders.get_diff(orderbook, 2)

      expect(diff[:create][create_order.side].length).to eq(1)
      expect(diff[:create][create_order.side][0].price).to eq(create_order.price)
      expect(diff[:create][create_order.side][0].amount).to eq(create_order.amount)
      expect(diff[:update][update_order.side].length).to eq(1)
      expect(diff[:update][update_order.side][0].price).to eq(update_order.price)
      expect(diff[:update][update_order.side][0].amount).to eq(update_order_ob.amount - update_order.amount)
      expect(diff[:delete][delete_order.side].length).to eq(1)
      expect(diff[:delete][delete_order.side][0]).to eq(delete_order.id)
    end
  end
end