describe Arke::Orderbook::Aggregated do
  let(:market)     { 'ethusd' }
  let(:orderbook)  { Arke::Orderbook::Orderbook.new(market) }
  let(:order_sell_0)     { Arke::Order.new('ethusd', 5, 2, :sell) }
  let(:order_sell_1)     { Arke::Order.new('ethusd', 8, 1, :sell) }
  let(:order_sell_2)     { Arke::Order.new('ethusd', 2, 1, :sell) }
  let(:order_buy_0)      { Arke::Order.new('ethusd', 5, 1, :buy) }
  let(:order_buy_1)      { Arke::Order.new('ethusd', 8, 1, :buy) }
  let(:order_buy_2)      { Arke::Order.new('ethusd', 9, 1, :buy) }
  let(:price_points_buy) { [8, 6] }
  let(:price_points_sell) { [6, 8] }

  context "aggregate_side" do
    it 'aggregates sell orders according to given price points' do
      orderbook.update(order_sell_0)
      orderbook.update(order_sell_1)
      orderbook.update(order_sell_2)
      agg_ob, agg_vol = orderbook.aggregate_side(:sell, price_points_sell)
      expect(agg_ob.to_hash).to eq({
        4.0 => {:high_price => 5, :low_price => 2, :volume => 3, :weighted_price => 4.0},
        8.0 => {:high_price => 8, :low_price => 8, :volume => 1, :weighted_price => 8.0}
      })
      expect(agg_vol).to eq(4)
    end

    it 'aggregates buy orders according to given price points' do
      orderbook.update(order_buy_0)
      orderbook.update(order_buy_1)
      orderbook.update(order_buy_2)
      agg_ob, agg_vol = orderbook.aggregate_side(:buy, price_points_buy)
      expect(agg_ob.to_hash).to eq({
        5.0 => {:high_price=>5, :low_price=>5, :volume=>1, :weighted_price=>5.0},
        8.5 => {:high_price=>9, :low_price=>8, :volume=>2, :weighted_price=>8.5}
      })
      expect(agg_vol).to eq(3)
    end
  end

  context "aggregate orderbook with ranges without orders" do
    let (:sell_side) do
      ::RBTree[
        1000.0, 0.01,
        1000.5, 0.01,
        1001.0, 0.01,
        1010.0, 0.01,
        1011.0, 0.01,
        1020.0, 0.01,
        1021.0, 0.01,
      ]
    end
    let (:buy_side) do
      ::RBTree[
        1021.0, 0.01,
        1020.0, 0.01,
        1011.0, 0.01,
        1010.0, 0.01,
        1001.0, 0.01,
        1000.5, 0.01,
        1000.0, 0.01,
      ]
    end
    let(:orderbook)  { Arke::Orderbook::Orderbook.new(market, sell: sell_side, buy: buy_side) }
    let(:price_points_buy) do
      [1021, 1020, 1019, 1018, 1017]
    end
    let(:price_points_sell) do
      [1000, 1001, 1002, 1003, 1004]
    end

    it 'respects the number of price points' do
      sell_agg_ob, sell_volume_base, sell_volume_quote = orderbook.aggregate_side(:sell, price_points_sell)
      expect(sell_agg_ob.to_hash).to eq({
        1000.0 => {:high_price=>1000.0, :low_price=>1000.0, :volume=>0.01, :weighted_price=>1000.0},
        1000.75 => {:high_price=>1001, :low_price=>1000.5, :volume=>0.02, :weighted_price=>1000.75},
        1010.0 => {:high_price=>1010, :low_price=>1010, :volume=>0.01, :weighted_price=>1010.0},
        1010.9999999999999 => {:high_price=>1011.0, :low_price=>1011.0, :volume=>0.01, :weighted_price=>1010.9999999999999},
        1020.0000000000001 => {:high_price=>1020.0, :low_price=>1020.0, :volume=>0.01, :weighted_price=>1020.0000000000001},
      })
      expect(sell_volume_base).to eq(0.060000000000000005)
      expect(sell_volume_quote).to eq(60.425000000000004)

      buy_agg_ob, buy_volume_base, buy_volume_quote = orderbook.aggregate_side(:buy, price_points_buy)
      expect(buy_agg_ob.to_hash).to eq({
        1001.0 => {:high_price=>1001.0, :low_price=>1001.0, :volume=>0.01, :weighted_price=>1001.0},
        1010.0 => {:high_price=>1010.0, :low_price=>1010.0, :volume=>0.01, :weighted_price=>1010.0},
        1010.9999999999999 => {:high_price=>1011.0, :low_price=>1011.0, :volume=>0.01, :weighted_price=>1010.9999999999999},
        1020.0000000000001 => {:high_price=>1020.0, :low_price=>1020.0, :volume=>0.01, :weighted_price=>1020.0000000000001},
        1021.0000000000001 => {:high_price=>1021.0, :low_price=>1021.0, :volume=>0.01, :weighted_price=>1021.0000000000001},
      })
      expect(buy_volume_base).to eq(0.05)
      expect(buy_volume_quote).to eq(50.63)
    end
  end

  context "aggregate big orderbook" do
    let (:sell_side) do
      ::RBTree[
        12593.26, 0.009085,
        12593.48, 0.108702,
        12594.79, 0.146533,
        12595.0, 0.001029,
        12595.04, 0.003757,
        12595.27, 0.99975,
        12596.92, 0.5,
        12597.68, 0.005073,
        12597.7, 0.005287,
        12598.96, 0.014711,
        12598.98, 0.107198,
        12598.99, 1.106356,
        12599.0, 0.224343,
        12599.71, 0.081051,
        12599.73, 0.787677,
        12600.0, 5.609088,
        12600.05, 0.0015,
        12600.13, 0.001989,
        12600.3, 0.001938,
        12600.73, 0.11,
        12600.75, 0.001587,
        12600.82, 0.02,
        12600.93, 0.002168,
        12601.06, 0.019907,
        12601.13, 0.095336,
        12601.48, 0.001998
      ]
    end
    let(:orderbook)  { Arke::Orderbook::Orderbook.new(market, sell: sell_side) }
    let(:price_points_sell) do
      [12593.30, 12593.40, 12593.50, 12593.60, 12594.00, 12594.50, 12595, 12596, 12597, 12600]
    end

    it 'aggregates sell orders according to given price points' do
      agg_ob, volume_base, volume_quote = orderbook.aggregate_side(:sell, price_points_sell)
      expect(agg_ob.to_hash).to eq({
        12593.26 => {:high_price=>12593.26, :low_price=>12593.26, :volume=>0.009085, :weighted_price=>12593.26},
        12593.480000000001 => {:high_price=>12593.48, :low_price=>12593.48, :volume=>0.108702, :weighted_price=>12593.480000000001},
        12594.79 => {:high_price=>12594.79, :low_price=>12594.79, :volume=>0.146533, :weighted_price=>12594.79},
        12595.0 => {:high_price=>12595.0, :low_price=>12595.0, :volume=>0.001029, :weighted_price=>12595.0},
        12595.269138909845 => {:high_price=>12595.27, :low_price=>12595.04, :volume=>1.003507, :weighted_price=>12595.269138909845},
        12596.92 => {:high_price=>12596.92, :low_price=>12596.92, :volume=>0.5, :weighted_price=>12596.92},
        12597.68 => {:high_price=>12597.68, :low_price=>12597.68, :volume=>0.005073, :weighted_price=>12597.68},
        12597.7 => {:high_price=>12597.7, :low_price=>12597.7, :volume=>0.005287, :weighted_price=>12597.7},
        12598.990502626999 => {:high_price=>12599.0, :low_price=>12598.96, :volume=>1.452608, :weighted_price=>12598.990502626999},
        12599.999470173247 => {:high_price=>12601.48, :low_price=>12599.71, :volume=>6.734239, :weighted_price=>12599.999470173247},
      })
      expect(volume_base).to eq(9.966063)
      expect(volume_quote).to eq(125563.07389451)
    end
  end

  context "aggregate" do
    before(:each) do
      orderbook.update(order_sell_0)
      orderbook.update(order_sell_1)
      orderbook.update(order_sell_2)
      orderbook.update(order_buy_0)
      orderbook.update(order_buy_1)
      orderbook.update(order_buy_2)
    end

    it 'aggregates complete orderbook' do
      book = orderbook.aggregate(price_points_buy, price_points_sell)
      expect(book[:buy].to_hash).to eq({
        5.0 => {:high_price=>5, :low_price=>5, :volume=>1, :weighted_price=>5.0},
        8.5 => {:high_price=>9, :low_price=>8, :volume=>2, :weighted_price=>8.5}
      })
      expect(book[:sell].to_hash).to eq({
        4.0 => {:high_price => 5, :low_price => 2, :volume => 3, :weighted_price => 4.0},
        8.0 => {:high_price => 8, :low_price => 8, :volume => 1, :weighted_price => 8.0}
      })
      expect(book.volume_asks_base).to eq(4)
      expect(book.volume_bids_base).to eq(3.0)
      expect(book.volume_bids_quote).to eq(22)
      expect(book.volume_asks_quote).to eq(20)
    end

    it 'aggregates only bids side' do
      book = orderbook.aggregate(price_points_buy, nil)
      expect(book[:buy].to_hash).to eq({
        5.0 => {:high_price=>5, :low_price=>5, :volume=>1, :weighted_price=>5.0},
        8.5 => {:high_price=>9, :low_price=>8, :volume=>2, :weighted_price=>8.5}
      })
      expect(book[:sell].to_hash).to eq({})
    end

    it 'aggregates only asks side' do
      book = orderbook.aggregate(nil, price_points_sell)
      expect(book[:buy].to_hash).to eq({})
      expect(book[:sell].to_hash).to eq({
        4.0 => {:high_price => 5, :low_price => 2, :volume => 3, :weighted_price => 4.0},
        8.0 => {:high_price => 8, :low_price => 8, :volume => 1, :weighted_price => 8.0}
      })
    end

    context "to_ob" do
      it "returns a Orderbook object" do
        book = orderbook.aggregate(price_points_buy, price_points_sell).to_ob
        expect(book[:buy].to_hash).to eq({
          5.0 => 1,
          8.5 => 2,
        })
        expect(book[:sell].to_hash).to eq({
          4.0 => 3,
          8.0 => 1,
        })
        expect(book.volume_bids_base).to eq(3)
        expect(book.volume_asks_base).to eq(4)
        end
    end
  end

end
