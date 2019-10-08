# frozen_string_literal: true

describe Arke::Orderbook::Aggregated do
  let(:market)     { "ethusd" }
  let(:orderbook)  { Arke::Orderbook::Orderbook.new(market) }
  let(:order_sell_0)     { Arke::Order.new("ethusd", 5, 2, :sell) }
  let(:order_sell_1)     { Arke::Order.new("ethusd", 8, 1, :sell) }
  let(:order_sell_2)     { Arke::Order.new("ethusd", 2, 1, :sell) }
  let(:order_buy_0)      { Arke::Order.new("ethusd", 5, 1, :buy) }
  let(:order_buy_1)      { Arke::Order.new("ethusd", 8, 1, :buy) }
  let(:order_buy_2)      { Arke::Order.new("ethusd", 9, 1, :buy) }
  let(:price_points_buy) { [8, 6] }
  let(:price_points_sell) { [6, 8] }

  context "aggregate_side" do
    it "aggregates sell orders according to given price points" do
      orderbook.update(order_sell_0)
      orderbook.update(order_sell_1)
      orderbook.update(order_sell_2)
      agg_ob, agg_vol, agg_vol_quote = orderbook.aggregate_side(:sell, price_points_sell)
      expect(agg_ob.to_hash).to eq(
        4.0 => {high_price: 5, low_price: 2, volume: 3, weighted_price: 4.0},
        8.0 => {high_price: 8, low_price: 8, volume: 1, weighted_price: 8.0}
      )
      expect(agg_vol_quote).to eq(20.0)
      expect(agg_vol).to eq(4.0)
    end

    it "aggregates buy orders according to given price points" do
      orderbook.update(order_buy_0)
      orderbook.update(order_buy_1)
      orderbook.update(order_buy_2)
      agg_ob, agg_vol = orderbook.aggregate_side(:buy, price_points_buy)
      expect(agg_ob.to_hash).to eq(
        6.000000000000001 => {high_price: 6.0, low_price: 6.0, volume: 0.1, weighted_price: 6.000000000000001},
        8.5               => {high_price: 9.0, low_price: 8, volume: 2.0, weighted_price: 8.5}
      )
      expect(agg_vol).to eq(2.1)
    end
  end

  context "aggregate orderbook with ranges without orders" do
    let(:sell_side) do
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
    let(:buy_side) do
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
    let(:orderbook) { Arke::Orderbook::Orderbook.new(market, sell: sell_side, buy: buy_side) }
    let(:price_points_sell) do
      [1000, 1001, 1002, 1003, 1004]
    end
    let(:price_points_buy) do
      [1021, 1020, 1019, 1018, 1017]
    end

    it "respects the number of price points" do
      sell_agg_ob, sell_volume_base, sell_volume_quote = orderbook.aggregate_side(:sell, price_points_sell)
      expect(sell_agg_ob.to_hash).to eq(
        1000.0             => {high_price: 1000.0, low_price: 1000.0, volume: 0.01, weighted_price: 1000.0},
        1000.75            => {high_price: 1001.0, low_price: 1000.5, volume: 0.02, weighted_price: 1000.75},
        1002.0             => {high_price: 1002.0, low_price: 1002.0, volume: 0.1, weighted_price: 1002.0},
        1003.0000000000001 => {high_price: 1003.0, low_price: 1003.0, volume: 0.1, weighted_price: 1003.0000000000001},
        1004.0             => {high_price: 1004.0, low_price: 1004.0, volume: 0.1, weighted_price: 1004.0}
      )
      expect(sell_volume_base).to eq(0.33)
      expect(sell_volume_quote).to eq(330.915)

      buy_agg_ob, buy_volume_base, buy_volume_quote = orderbook.aggregate_side(:buy, price_points_buy)
      expect(buy_agg_ob.to_hash).to eq(
        1017.0             => {high_price: 1017.0, low_price: 1017.0, volume: 0.1, weighted_price: 1017.0},
        1018.0000000000001 => {high_price: 1018.0, low_price: 1018.0, volume: 0.1, weighted_price: 1018.0000000000001},
        1019.0             => {high_price: 1019.0, low_price: 1019.0, volume: 0.1, weighted_price: 1019.0},
        1020.0000000000001 => {high_price: 1020.0, low_price: 1020.0, volume: 0.01, weighted_price: 1020.0000000000001},
        1021.0000000000001 => {high_price: 1021.0, low_price: 1021.0, volume: 0.01, weighted_price: 1021.0000000000001}
      )
      expect(buy_volume_base).to eq(0.32000000000000006)
      expect(buy_volume_quote).to eq(325.81)
    end
  end

  context "aggregate orderbook with price points over the ranges" do
    let(:sell_side) do
      ::RBTree[
        1000.0, 0.01,
        1001.0, 0.01,
        1002.0, 0.01,
      ]
    end
    let(:buy_side) do
      ::RBTree[
        999, 0.01,
        998, 0.01,
      ]
    end
    let(:orderbook) { Arke::Orderbook::Orderbook.new(market, sell: sell_side, buy: buy_side) }
    let(:price_points_sell) do
      [1000, 1001, 1005, 1010]
    end
    let(:price_points_buy) do
      [999, 990, 980]
    end

    it "respects the number of price points" do
      sell_agg_ob, sell_volume_base, sell_volume_quote = orderbook.aggregate_side(:sell, price_points_sell)
      expect(sell_agg_ob.to_hash).to eq(
        1000.0             => {high_price: 1000.0, low_price: 1000.0, volume: 0.01, weighted_price: 1000.0},
        1001.0             => {high_price: 1001.0, low_price: 1001.0, volume: 0.01, weighted_price: 1001.0},
        1001.9999999999999 => {high_price: 1002.0, low_price: 1002.0, volume: 0.01, weighted_price: 1001.9999999999999},
        1010.0             => {high_price: 1010.0, low_price: 1010.0, volume: 0.1, weighted_price: 1010.0}
      )
      expect(sell_volume_base).to eq(0.13)
      expect(sell_volume_quote).to eq(131.03)

      buy_agg_ob, buy_volume_base, buy_volume_quote = orderbook.aggregate_side(:buy, price_points_buy)
      expect(buy_agg_ob.to_hash).to eq(
        980.0 => {high_price: 980.0, low_price: 980.0, volume: 0.1, weighted_price: 980.0},
        998.0 => {high_price: 998.0, low_price: 998.0, volume: 0.01, weighted_price: 998.0},
        999.0 => {high_price: 999.0, low_price: 999.0, volume: 0.01, weighted_price: 999.0}
      )

      expect(buy_volume_base).to eq(0.12000000000000001)
      expect(buy_volume_quote).to eq(117.97)
    end
  end

  context "aggregate big orderbook" do
    let(:sell_side) do
      ::RBTree[
        12_593.26, 0.009085,
        12_593.48, 0.108702,
        12_594.79, 0.146533,
        12_595.0, 0.001029,
        12_595.04, 0.003757,
        12_595.27, 0.99975,
        12_596.92, 0.5,
        12_597.68, 0.005073,
        12_597.7, 0.005287,
        12_598.96, 0.014711,
        12_598.98, 0.107198,
        12_598.99, 1.106356,
        12_599.0, 0.224343,
        12_599.71, 0.081051,
        12_599.73, 0.787677,
        12_600.0, 5.609088,
        12_600.05, 0.0015,
        12_600.13, 0.001989,
        12_600.3, 0.001938,
        12_600.73, 0.11,
        12_600.75, 0.001587,
        12_600.82, 0.02,
        12_600.93, 0.002168,
        12_601.06, 0.019907,
        12_601.13, 0.095336,
        12_601.48, 0.001998
      ]
    end
    let(:orderbook) { Arke::Orderbook::Orderbook.new(market, sell: sell_side) }
    let(:price_points_sell) do
      [12_593.30, 12_593.40, 12_593.50, 12_593.60, 12_594.00, 12_594.50, 12_595, 12_596, 12_597, 12_600]
    end

    it "aggregates sell orders according to given price points" do
      agg_ob, volume_base, volume_quote = orderbook.aggregate_side(:sell, price_points_sell)
      expect(agg_ob.to_hash).to eq(
        12_593.26           => {high_price: 12_593.26, low_price: 12_593.26, volume: 0.009085, weighted_price: 12_593.26},
        12_593.400000000001 => {high_price: 12_593.4, low_price: 12_593.4, volume: 0.1, weighted_price: 12_593.400000000001},
        12_593.480000000001 => {high_price: 12_593.48, low_price: 12_593.48, volume: 0.108702, weighted_price: 12_593.480000000001},
        12_593.6            => {high_price: 12_593.6, low_price: 12_593.6, volume: 0.1, weighted_price: 12_593.6},
        12_594.0            => {high_price: 12_594.0, low_price: 12_594.0, volume: 0.1, weighted_price: 12_594.0},
        12_594.5            => {high_price: 12_594.5, low_price: 12_594.5, volume: 0.1, weighted_price: 12_594.5},
        12_594.791464401405 => {high_price: 12_595.0, low_price: 12_594.79, volume: 0.147562, weighted_price: 12_594.791464401405},
        12_595.269138909845 => {high_price: 12_595.27, low_price: 12_595.04, volume: 1.003507, weighted_price: 12_595.269138909845},
        12_596.92           => {high_price: 12_596.92, low_price: 12_596.92, volume: 0.5, weighted_price: 12_596.92},
        12_599.782576758163 => {high_price: 12_600.0, low_price: 12_597.68, volume: 7.940784, weighted_price: 12_599.782576758163}
      )
      expect(volume_base).to eq(10.109639999999999)
      expect(volume_quote).to eq(127_369.46148490999)
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

    it "aggregates complete orderbook" do
      book = orderbook.aggregate(price_points_buy, price_points_sell, 0.1, 0.1)
      expect(book[:buy].to_hash).to eq(
        6.000000000000001 => {high_price: 6.0, low_price: 6.0, volume: 0.1, weighted_price: 6.000000000000001},
        8.5               => {high_price: 9, low_price: 8, volume: 2, weighted_price: 8.5}
      )
      expect(book[:sell].to_hash).to eq(
        4.0 => {high_price: 5, low_price: 2, volume: 3, weighted_price: 4.0},
        8.0 => {high_price: 8, low_price: 8, volume: 1, weighted_price: 8.0}
      )
      expect(book.volume_asks_base).to eq(4)
      expect(book.volume_bids_base).to eq(2.1)
      expect(book.volume_bids_quote).to eq(17.6)
      expect(book.volume_asks_quote).to eq(20)
    end

    it "aggregates only bids side" do
      book = orderbook.aggregate(price_points_buy, nil, nil, 0.1)
      expect(book[:buy].to_hash).to eq(
        6.000000000000001 => {high_price: 6.0, low_price: 6.0, volume: 0.1, weighted_price: 6.000000000000001},
        8.5               => {high_price: 9.0, low_price: 8, volume: 2.0, weighted_price: 8.5}
      )
      expect(book[:sell].to_hash).to eq({})
    end

    it "aggregates only asks side" do
      book = orderbook.aggregate(nil, price_points_sell, 0.1, nil)
      expect(book[:buy].to_hash).to eq({})
      expect(book[:sell].to_hash).to eq(
        4.0 => {high_price: 5, low_price: 2, volume: 3, weighted_price: 4.0},
        8.0 => {high_price: 8, low_price: 8, volume: 1, weighted_price: 8.0}
      )
    end

    context "to_ob" do
      it "returns a Orderbook object" do
        book = orderbook.aggregate(price_points_buy, price_points_sell, 0.1, 0.1).to_ob
        expect(book[:buy].to_hash).to eq(
          6.000000000000001 => 0.1,
          8.5               => 2.0
        )
        expect(book[:sell].to_hash).to eq(
          4.0 => 3,
          8.0 => 1
        )
        expect(book.volume_bids_base).to eq(2.1)
        expect(book.volume_asks_base).to eq(4)
      end
    end
  end
end
