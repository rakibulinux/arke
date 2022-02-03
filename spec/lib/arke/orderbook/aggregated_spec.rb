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
  let(:price_points_buy) do
    [8, 6].map {|price| ::Arke::PricePoint.new(price) }
  end
  let(:price_points_sell) do
    [6, 8].map {|price| ::Arke::PricePoint.new(price) }
  end

  context "aggregate_side" do
    it "aggregates sell orders according to given price points" do
      orderbook.update(order_sell_0)
      orderbook.update(order_sell_1)
      orderbook.update(order_sell_2)
      agg_ob, agg_vol, agg_vol_quote = orderbook.aggregate_side(:sell, price_points_sell)
      expect(agg_ob.to_hash).to eq(
        4.0.to_d => {high_price: 5, low_price: 2, volume: 3, weighted_price: 4.0},
        8.0.to_d => {high_price: 8, low_price: 8, volume: 1, weighted_price: 8.0}
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
        6.0.to_d => {high_price: 6.0, low_price: 6.0, volume: 0.1, weighted_price: 6.0},
        8.5.to_d => {high_price: 9.0, low_price: 8, volume: 2.0, weighted_price: 8.5}
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
      [1000, 1001, 1002, 1003, 1004].map {|price| ::Arke::PricePoint.new(price) }
    end
    let(:price_points_buy) do
      [1021, 1020, 1019, 1018, 1017].map {|price| ::Arke::PricePoint.new(price) }
    end

    it "respects the number of price points" do
      sell_agg_ob, sell_volume_base, sell_volume_quote = orderbook.aggregate_side(:sell, price_points_sell)
      expect(sell_agg_ob.to_hash).to eq(
        1000.to_d    => {high_price: 1000.to_d, low_price: 1000.0.to_d, volume: 0.01.to_d, weighted_price: 1000.to_d},
        1000.75.to_d => {high_price: 1001.to_d, low_price: 1000.5.to_d, volume: 0.02.to_d, weighted_price: 1000.75.to_d},
        1002.to_d    => {high_price: 1002.to_d, low_price: 1002.0.to_d, volume: 0.1.to_d, weighted_price: 1002.to_d},
        1003.to_d    => {high_price: 1003.to_d, low_price: 1003.0.to_d, volume: 0.1.to_d, weighted_price: 1003.to_d},
        1004.to_d    => {high_price: 1004.to_d, low_price: 1004.0.to_d, volume: 0.1.to_d, weighted_price: 1004.to_d}
      )
      expect(sell_volume_base).to eq(0.33.to_d)
      expect(sell_volume_quote).to eq(330.915.to_d)

      buy_agg_ob, buy_volume_base, buy_volume_quote = orderbook.aggregate_side(:buy, price_points_buy)
      expect(buy_agg_ob.to_hash).to eq(
        1017.to_d => {high_price: 1017.to_d, low_price: 1017.to_d, volume: 0.1.to_d, weighted_price: 1017.to_d},
        1018.to_d => {high_price: 1018.to_d, low_price: 1018.to_d, volume: 0.1.to_d, weighted_price: 1018.to_d},
        1019.to_d => {high_price: 1019.to_d, low_price: 1019.to_d, volume: 0.1.to_d, weighted_price: 1019.to_d},
        1020.to_d => {high_price: 1020.to_d, low_price: 1020.to_d, volume: 0.01.to_d, weighted_price: 1020.to_d},
        1021.to_d => {high_price: 1021.to_d, low_price: 1021.to_d, volume: 0.01.to_d, weighted_price: 1021.to_d}
      )
      expect(buy_volume_base).to eq(0.32.to_d)
      expect(buy_volume_quote).to eq(325.81.to_d)
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
      [1000, 1001, 1005, 1010].map {|price| ::Arke::PricePoint.new(price) }
    end
    let(:price_points_buy) do
      [999, 990, 980].map {|price| ::Arke::PricePoint.new(price) }
    end

    it "respects the number of price points" do
      sell_agg_ob, sell_volume_base, sell_volume_quote = orderbook.aggregate_side(:sell, price_points_sell)
      expect(sell_agg_ob.to_hash).to eq(
        1000.to_d => {high_price: 1000.to_d, low_price: 1000.to_d, volume: 0.01.to_d, weighted_price: 1000.to_d},
        1001.to_d => {high_price: 1001.to_d, low_price: 1001.to_d, volume: 0.01.to_d, weighted_price: 1001.to_d},
        1002.to_d => {high_price: 1002.to_d, low_price: 1002.to_d, volume: 0.01.to_d, weighted_price: 1002.to_d},
        1010.to_d => {high_price: 1010.to_d, low_price: 1010.to_d, volume: 0.1.to_d, weighted_price: 1010.to_d}
      )
      expect(sell_volume_base).to eq(0.13.to_d)
      expect(sell_volume_quote).to eq(131.03.to_d)

      buy_agg_ob, buy_volume_base, buy_volume_quote = orderbook.aggregate_side(:buy, price_points_buy)
      expect(buy_agg_ob.to_hash).to eq(
        980.to_d => {high_price: 980.to_d, low_price: 980.to_d, volume: 0.1.to_d, weighted_price: 980.to_d},
        998.to_d => {high_price: 998.to_d, low_price: 998.to_d, volume: 0.01.to_d, weighted_price: 998.to_d},
        999.to_d => {high_price: 999.to_d, low_price: 999.to_d, volume: 0.01.to_d, weighted_price: 999.to_d}
      )

      expect(buy_volume_base).to eq(0.12.to_d)
      expect(buy_volume_quote).to eq(117.97.to_d)
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
        .map {|price| ::Arke::PricePoint.new(price) }
    end

    it "aggregates sell orders according to given price points" do
      agg_ob, volume_base, volume_quote = orderbook.aggregate_side(:sell, price_points_sell)
      expect(agg_ob.to_hash).to eq(
        (125_932_600_000_000_013_862.to_d * 1e-16) => {high_price: 12_593.26.to_d, low_price: 12_593.26.to_d, volume: "0.009085".to_d, weighted_price: (125_932_600_000_000_013_862.to_d * 1e-16)},
        12_593.40.to_d                             => {high_price: 12_593.4.to_d, low_price: 12_593.4.to_d, volume: "0.1".to_d, weighted_price: 12_593.4.to_d},
        12_593.48.to_d                             => {high_price: 12_593.48.to_d, low_price: 12_593.48.to_d, volume: "0.108702".to_d, weighted_price: 12_593.48.to_d},
        12_593.60.to_d                             => {high_price: 12_593.6.to_d, low_price: 12_593.6.to_d, volume: "0.1".to_d, weighted_price: 12_593.6.to_d},
        12_594.00.to_d                             => {high_price: 12_594.0.to_d, low_price: 12_594.0.to_d, volume: "0.1".to_d, weighted_price: 12_594.0.to_d},
        12_594.50.to_d                             => {high_price: 12_594.5.to_d, low_price: 12_594.5.to_d, volume: "0.1".to_d, weighted_price: 12_594.5.to_d},
        (125_947_914_644_014_041_555.to_d * 1e-16) => {high_price: 12_595.0.to_d, low_price: 12_594.79.to_d, volume: "0.147562".to_d, weighted_price: (125_947_914_644_014_041_555.to_d * 1e-16)},
        (1_259_526_913_890_984_318.to_d * 1e-14)   => {high_price: 12_595.27.to_d, low_price: 12_595.04.to_d, volume: "1.003507".to_d, weighted_price: (1_259_526_913_890_984_318.to_d * 1e-14)},
        12_596.92.to_d                             => {high_price: 12_596.92.to_d, low_price: 12_596.92.to_d, volume: "0.5".to_d, weighted_price: 12_596.92.to_d},
        (125_997_825_767_581_638_047.to_d * 1e-16) => {high_price: 12_600.0.to_d, low_price: 12_597.68.to_d, volume: "7.940784".to_d, weighted_price: (125_997_825_767_581_638_047.to_d * 1e-16)}
      )
      expect(volume_base).to eq(10_109_639_999_999_999_999.to_d * 1e-18)
      expect(volume_quote).to eq(12_736_946_148_490_999_901.to_d * 1e-14)
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
      book = orderbook.aggregate(price_points_buy, price_points_sell, 0.1)
      expect(book[:buy].to_hash).to eq(
        6.0.to_d => {high_price: 6.to_d, low_price: 6.to_d, volume: 0.1.to_d, weighted_price: 6.to_d},
        8.5.to_d => {high_price: 9.to_d, low_price: 8.to_d, volume: 2.to_d, weighted_price: 8.5.to_d}
      )
      expect(book[:sell].to_hash).to eq(
        4.0.to_d => {high_price: 5, low_price: 2, volume: 3, weighted_price: 4.0},
        8.0.to_d => {high_price: 8, low_price: 8, volume: 1, weighted_price: 8.0}
      )
      expect(book.volume_asks_base).to eq(4)
      expect(book.volume_bids_base).to eq(2.1)
      expect(book.volume_bids_quote).to eq(17.6)
      expect(book.volume_asks_quote).to eq(20)
    end

    it "aggregates only bids side" do
      book = orderbook.aggregate(price_points_buy, nil, 0.1)
      expect(book[:buy].to_hash).to eq(
        6.0.to_d => {high_price: 6.to_d, low_price: 6.to_d, volume: 0.1.to_d, weighted_price: 6.0.to_d},
        8.5.to_d => {high_price: 9.to_d, low_price: 8.to_d, volume: 2.0.to_d, weighted_price: 8.5.to_d}
      )
      expect(book[:sell].to_hash).to eq({})
    end

    it "aggregates only asks side" do
      book = orderbook.aggregate(nil, price_points_sell, 0.1)
      expect(book[:buy].to_hash).to eq({})
      expect(book[:sell].to_hash).to eq(
        4.0.to_d => {high_price: 5, low_price: 2, volume: 3, weighted_price: 4.0},
        8.0.to_d => {high_price: 8, low_price: 8, volume: 1, weighted_price: 8.0}
      )
    end

    context "to_ob" do
      it "returns a Orderbook object" do
        book = orderbook.aggregate(price_points_buy, price_points_sell, 0.1).to_ob
        expect(book[:buy].to_hash).to eq(
          6.0.to_d => 0.1.to_d,
          8.5.to_d => 2.0.to_d
        )
        expect(book[:sell].to_hash).to eq(
          4.0.to_d => 3.to_d,
          8.0.to_d => 1.to_d
        )
        expect(book.volume_bids_base).to eq(2.1.to_d)
        expect(book.volume_asks_base).to eq(4.to_d)
      end
    end
  end
end
