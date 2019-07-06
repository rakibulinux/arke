describe Arke::Orderbook::Orderbook do
  let(:market)     { 'ethusd' }
  let(:orderbook)  { Arke::Orderbook::Orderbook.new(market) }

  context 'orderbook#add' do
    let(:order_buy)   { Arke::Order.new(market, 1, 1, :buy) }
    let(:order_sell)  { Arke::Order.new(market, 1, 1, :sell) }
    let(:order_sell2) { Arke::Order.new(market, 1, 1, :sell) }

    it 'adds buy order to orderbook' do
      orderbook.update(order_buy)

      expect(orderbook.book[:buy]).not_to be_nil
      expect(orderbook.book[:buy][order_buy.price]).not_to be_nil
    end

    it 'adds sell order to orderbook' do
      orderbook.update(order_sell)

      expect(orderbook.book[:sell]).not_to be_nil
      expect(orderbook.book[:sell][order_sell.price]).not_to be_nil
    end

    it 'updates order with the same price' do
      orderbook.update(order_sell)
      orderbook.update(order_sell2)

      expect(orderbook.book[:sell][order_sell.price]).to eq(order_sell2.amount)
    end
  end

  context 'orderbook#remove' do
    let(:order_buy)   { Arke::Order.new(market, 1, 1, :buy) }

    it 'removes correct order from orderbook' do
      orderbook.update(order_buy)
      orderbook.update(Arke::Order.new(market, order_buy.price, 1, :buy))
      orderbook.update(Arke::Order.new(market, 11, 1, :sell))

      orderbook.delete(order_buy)

      expect(orderbook.contains?(order_buy)).to eq(false)
      expect(orderbook.book[:buy][order_buy.price]).to be_nil
      expect(orderbook.book[:sell]).not_to be_nil
    end

    it 'does nothing if non existing id' do
      orderbook.update(order_buy)

      orderbook.delete(Arke::Order.new(market, 10, 1, :buy))

      expect(orderbook.book[:buy]).not_to be_nil
      expect(orderbook.contains?(order_buy)).to eq(true)
    end
  end

  context 'orderbook#merge' do
    let(:ob1) { Arke::Orderbook::Orderbook.new(market) }
    let(:ob2) { Arke::Orderbook::Orderbook.new(market) }
    let(:ob3) { Arke::Orderbook::Orderbook.new(market) }

    it 'merges two orderbooks into one' do
      ob1.update(Arke::Order.new(market, 10, 10, :sell))
      ob1.update(Arke::Order.new(market, 20, 15, :sell))
      ob1.update(Arke::Order.new(market, 25, 5, :sell))

      ob2.update(Arke::Order.new(market, 10, 30, :sell))
      ob2.update(Arke::Order.new(market, 20, 20, :sell))
      ob2.update(Arke::Order.new(market, 10, 10, :buy))

      ob3.update(Arke::Order.new(market, 10, 40, :sell))
      ob3.update(Arke::Order.new(market, 20, 35, :sell))
      ob3.update(Arke::Order.new(market, 25, 5, :sell))
      ob3.update(Arke::Order.new(market, 10, 10, :buy))

      ob1.merge!(ob2)

      expect(ob1.book[:index]).to eq(ob3.book[:index])
      expect(ob1.book[:sell]).to eq(ob3.book[:sell])
    end
  end

  context "adjust_volume" do
    let(:price_points_buy) { [8, 6] }
    let(:price_points_sell) { [6, 8] }
    let(:order_sell_0)     { Arke::Order.new('ethusd', 5, 1, :sell) }
    let(:order_sell_1)     { Arke::Order.new('ethusd', 8, 1, :sell) }
    let(:order_sell_2)     { Arke::Order.new('ethusd', 2, 1, :sell) }
    let(:order_buy_0)      { Arke::Order.new('ethusd', 5, 1, :buy) }
    let(:order_buy_1)      { Arke::Order.new('ethusd', 8, 1, :buy) }
    let(:order_buy_2)      { Arke::Order.new('ethusd', 9, 1, :buy) }

    before(:each) do
      orderbook.update(order_sell_0)
      orderbook.update(order_sell_1)
      orderbook.update(order_sell_2)
      orderbook.update(order_buy_0)
      orderbook.update(order_buy_1)
      orderbook.update(order_buy_2)
    end

    it "adjusts volume based on base volume requirements" do
      book = orderbook.aggregate(price_points_buy, price_points_sell)
              .to_ob
              .adjust_volume(0.2, 0.3)
      expect(book[:buy].to_hash).to eq({
        5.0 => 0.06666666666666667,
        8.5 => 0.13333333333333333,
      })
      expect(book[:sell].to_hash).to eq({
        3.5 => 0.19999999999999998,
        8.0 => 0.09999999999999999,
      })
      expect(book.volume_bids_base).to eq(0.2)
      expect(book.volume_asks_base).to eq(0.3)
      expect(book.volume_bids_quote).to eq(1.4666666666666666)
      expect(book.volume_asks_quote).to eq(1.5)
    end

    it "stops when reaching quote limit" do
      book = orderbook.aggregate(price_points_buy, price_points_sell)
              .to_ob
              .adjust_volume(0.2, 0.3, 1.1, 1.2)
      expect(book[:buy].to_hash).to eq({
        8.5 => 0.12941176470588237,
      })
      expect(book[:sell].to_hash).to eq({
        3.5 => 0.19999999999999998,
        8.0 => 0.0625,
      })
      expect(book.volume_bids_base).to eq(0.12941176470588237)
      expect(book.volume_asks_base).to eq(0.26249999999999996)
      expect(book.volume_bids_quote).to eq(1.1)
      expect(book.volume_asks_quote).to eq(1.2)
    end

    it "does nothing if the orderbook volume is lower than the provided limit" do
      book = orderbook.aggregate(price_points_buy, price_points_sell)
              .to_ob
              .adjust_volume(4, 6)
      expect(book[:buy].to_hash).to eq({
        5.0 => 1,
        8.5 => 2,
      })
      expect(book[:sell].to_hash).to eq({
        3.5 => 2,
        8.0 => 1,
      })
      expect(book.volume_bids_base).to eq(3)
      expect(book.volume_asks_base).to eq(3)
    end

    it "does nothing if the limits are nil" do
      book = orderbook.aggregate(price_points_buy, price_points_sell)
              .to_ob
              .adjust_volume(nil, nil)
      expect(book[:buy].to_hash).to eq({
        5.0 => 1,
        8.5 => 2,
      })
      expect(book[:sell].to_hash).to eq({
        3.5 => 2,
        8.0 => 1,
      })
      expect(book.volume_bids_base).to eq(3)
      expect(book.volume_asks_base).to eq(3)
    end

  end

end
