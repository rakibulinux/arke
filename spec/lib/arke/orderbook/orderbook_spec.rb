# frozen_string_literal: true

describe ::Arke::Orderbook::Orderbook do
  let(:market)     { "ethusd" }
  let(:orderbook)  { ::Arke::Orderbook::Orderbook.new(market) }

  context "orderbook#add" do
    let(:order_buy)   { ::Arke::Order.new(market, 1, 1, :buy) }
    let(:order_sell)  { ::Arke::Order.new(market, 1, 1, :sell) }
    let(:order_sell2) { ::Arke::Order.new(market, 1, 1, :sell) }

    it "adds buy order to orderbook" do
      orderbook.update(order_buy)

      expect(orderbook.book[:buy]).not_to be_nil
      expect(orderbook.book[:buy][order_buy.price]).not_to be_nil
    end

    it "adds sell order to orderbook" do
      orderbook.update(order_sell)

      expect(orderbook.book[:sell]).not_to be_nil
      expect(orderbook.book[:sell][order_sell.price]).not_to be_nil
    end

    it "updates order with the same price" do
      orderbook.update(order_sell)
      orderbook.update(order_sell2)

      expect(orderbook.book[:sell][order_sell.price]).to eq(order_sell2.amount)
    end
  end

  context "orderbook#remove" do
    let(:order_buy) { ::Arke::Order.new(market, 1, 1, :buy) }

    it "removes correct order from orderbook" do
      orderbook.update(order_buy)
      orderbook.update(::Arke::Order.new(market, order_buy.price, 1, :buy))
      orderbook.update(::Arke::Order.new(market, 11, 1, :sell))

      orderbook.delete(order_buy)

      expect(orderbook.contains?(order_buy)).to eq(false)
      expect(orderbook.book[:buy][order_buy.price]).to be_nil
      expect(orderbook.book[:sell]).not_to be_nil
    end

    it "does nothing if non existing id" do
      orderbook.update(order_buy)

      orderbook.delete(::Arke::Order.new(market, 10, 1, :buy))

      expect(orderbook.book[:buy]).not_to be_nil
      expect(orderbook.contains?(order_buy)).to eq(true)
    end
  end

  context "orderbook#merge" do
    let(:ob1) { ::Arke::Orderbook::Orderbook.new(market) }
    let(:ob2) { ::Arke::Orderbook::Orderbook.new(market) }
    let(:ob3) { ::Arke::Orderbook::Orderbook.new(market) }

    it "merges two orderbooks into one" do
      ob1.update(::Arke::Order.new(market, 10, 10, :sell))
      ob1.update(::Arke::Order.new(market, 20, 15, :sell))
      ob1.update(::Arke::Order.new(market, 25, 5, :sell))

      ob2.update(::Arke::Order.new(market, 10, 30, :sell))
      ob2.update(::Arke::Order.new(market, 20, 20, :sell))
      ob2.update(::Arke::Order.new(market, 10, 10, :buy))

      ob3.update(::Arke::Order.new(market, 10, 40, :sell))
      ob3.update(::Arke::Order.new(market, 20, 35, :sell))
      ob3.update(::Arke::Order.new(market, 25, 5, :sell))
      ob3.update(::Arke::Order.new(market, 10, 10, :buy))

      ob1.merge!(ob2)

      expect(ob1.book[:index]).to eq(ob3.book[:index])
      expect(ob1.book[:sell]).to eq(ob3.book[:sell])
    end
  end

  context "adjust_volume" do
    let(:price_points_buy) { [::Arke::PricePoint.new(8), ::Arke::PricePoint.new(6)] }
    let(:price_points_sell) { [::Arke::PricePoint.new(6), ::Arke::PricePoint.new(8)] }
    let(:order_sell_0)     { ::Arke::Order.new("ethusd", 5, 1, :sell) }
    let(:order_sell_1)     { ::Arke::Order.new("ethusd", 8, 1, :sell) }
    let(:order_sell_2)     { ::Arke::Order.new("ethusd", 2, 1, :sell) }
    let(:order_buy_0)      { ::Arke::Order.new("ethusd", 5, 1, :buy) }
    let(:order_buy_1)      { ::Arke::Order.new("ethusd", 8, 1, :buy) }
    let(:order_buy_2)      { ::Arke::Order.new("ethusd", 9, 1, :buy) }

    before(:each) do
      orderbook.update(order_sell_0)
      orderbook.update(order_sell_1)
      orderbook.update(order_sell_2)
      orderbook.update(order_buy_0)
      orderbook.update(order_buy_1)
      orderbook.update(order_buy_2)
    end

    it "adjusts volume based on base volume requirements" do
      book = orderbook.aggregate(price_points_buy, price_points_sell, 0.1)
                      .to_ob
                      .adjust_volume(0.2, 0.3)
      expect(book[:buy].to_hash).to eq(
        6.0.to_d => (95_238_095_238_095.to_d * 1e-16),
        8.5.to_d => (1_904_761_904_761_905.to_d * 1e-16)
      )
      expect(book[:sell].to_hash).to eq(
        3.5.to_d => 0.20.to_d,
        8.0.to_d => 0.10.to_d
      )
      expect(book.volume_bids_base).to eq(0.2.to_d)
      expect(book.volume_asks_base).to eq(0.3.to_d)
      expect(book.volume_bids_quote).to eq(16_761_904_761_904_762.to_d * 1e-16)
      expect(book.volume_asks_quote).to eq(1.5.to_d)
    end

    it "stops when reaching quote limit" do
      book = orderbook.aggregate(price_points_buy, price_points_sell, 0.1)
                      .to_ob
                      .adjust_volume(0.2, 0.3, 1.1, 1.2)
      expect(book[:buy].to_hash).to eq(
        8.5.to_d => (1_294_117_647_058_824.to_d * 1e-16)
      )
      expect(book[:sell].to_hash).to eq(
        3.5.to_d => 0.20.to_d,
        8.0.to_d => 0.0625.to_d
      )
      expect(book.volume_bids_base).to eq(1_294_117_647_058_824.to_d * 1e-16)
      expect(book.volume_asks_base).to eq(0.2625.to_d)
      expect(book.volume_bids_quote).to eq(1.1.to_d)
      expect(book.volume_asks_quote).to eq(1.2.to_d)
    end

    it "does nothing if the orderbook volume is lower than the provided limit" do
      book = orderbook.aggregate(price_points_buy, price_points_sell, 0.1)
                      .to_ob
                      .adjust_volume(4, 6)
      expect(book[:buy].to_hash).to eq(
        6.0.to_d => 0.1.to_d,
        8.5.to_d => 2.0.to_d
      )
      expect(book[:sell].to_hash).to eq(
        3.5.to_d => 2.to_d,
        8.0.to_d => 1.to_d
      )
      expect(book.volume_bids_base).to eq(2.1.to_d)
      expect(book.volume_asks_base).to eq(3.to_d)
    end

    it "does nothing if the limits are nil" do
      book = orderbook.aggregate(price_points_buy, price_points_sell, 0.1)
                      .to_ob
                      .adjust_volume(nil, nil)
      expect(book[:buy].to_hash).to eq(
        6.0.to_d => 0.1.to_d,
        8.5.to_d => 2.0.to_d
      )
      expect(book[:sell].to_hash).to eq(
        3.5.to_d => 2.to_d,
        8.0.to_d => 1.to_d
      )
      expect(book.volume_bids_base).to eq(2.1.to_d)
      expect(book.volume_asks_base).to eq(3.to_d)
    end
  end

  context "adjust_volume_simple" do
    let(:ob) { ::Arke::Orderbook::Orderbook.new(market) }

    before(:each) do
      ob.update(::Arke::Order.new("ethusd", 5, 4, :sell))
      ob.update(::Arke::Order.new("ethusd", 8, 4, :sell))
      ob.update(::Arke::Order.new("ethusd", 2, 4, :sell))

      ob.update(::Arke::Order.new("ethusd", 5, 3, :buy))
      ob.update(::Arke::Order.new("ethusd", 8, 3, :buy))
      ob.update(::Arke::Order.new("ethusd", 9, 3, :buy))
    end

    it "adjusts volume according to requirements" do
      book = ob.adjust_volume_simple(6, 3) # Asks (Sell) / Bids (Buy)
      expect(book[:sell].to_hash).to eq(
        5.0.to_d => 2,
        8.0.to_d => 2,
        2.0.to_d => 2
      )
      expect(book[:buy].to_hash).to eq(
        6.0.to_d => 1,
        8.0.to_d => 1,
        9.0.to_d => 1
      )
      # expect(book.volume_bids_base).to eq(0.2.to_d)
      # expect(book.volume_asks_base).to eq(0.3.to_d)
      # expect(book.volume_bids_quote).to eq(16_761_904_761_904_762.to_d * 1e-16)
      # expect(book.volume_asks_quote).to eq(1.5.to_d)
    end
  end
end
