# frozen_string_literal: true

describe Arke::Exchange::Kraken do
  include_context "kraken public"

  let(:exchange_config) do
    {
      "driver" => "kraken",
    }
  end
  let(:kraken) { Arke::Exchange::Kraken.new(exchange_config) }
  let(:market_id) { "XBTUSD" }

  let(:market) { Arke::Market.new(market_id, kraken) }

  context "market_config" do
    it "returns market configuration" do
      expect(kraken.market_config("XBTUSD")).to eq(
        "id"               => "XBTUSD",
        "base_unit"        => "XXBT",
        "quote_unit"       => "ZUSD",
        "min_price"        => nil,
        "max_price"        => nil,
        "min_amount"       => nil,
        "amount_precision" => 8,
        "price_precision"  => 1
      )
    end
  end

  context "public endpoints" do
    context "update_orderbook" do
      it "fetches the orderbook" do
        market.update_orderbook
        expect(market.orderbook.book[:buy].size).to eq(100)
        expect(market.orderbook.book[:sell].size).to eq(100)
        expect(market.orderbook.book[:buy].first).to eq([7203.3.to_d, 5.413.to_d])
        expect(market.orderbook.book[:sell].first).to eq([7203.4.to_d, 13.209.to_d])
      end
    end

    context "markets" do
      it "returns the list of markets" do
        expect(kraken.markets).to eq(JSON.parse(file_fixture("kraken/markets.json").read))
      end
    end

    context "currencies" do
      it "returns the list of assets" do
        expect(kraken.currencies).to eq(
          [
            {"id" => "ADA", "type" => "coin"},
            {"id" => "ATOM", "type" => "coin"},
            {"id" => "BAT", "type" => "coin"},
            {"id" => "BCH", "type" => "coin"},
            {"id" => "BSV", "type" => "coin"},
            {"id" => "CHF", "type" => "coin"},
            {"id" => "DAI", "type" => "coin"},
            {"id" => "DASH", "type" => "coin"},
            {"id" => "EOS", "type" => "coin"},
            {"id" => "GNO", "type" => "coin"},
            {"id" => "ICX", "type" => "coin"},
            {"id" => "FEE", "type" => "coin"},
            {"id" => "LINK", "type" => "coin"},
            {"id" => "LSK", "type" => "coin"},
            {"id" => "NANO", "type" => "coin"},
            {"id" => "OMG", "type" => "coin"},
            {"id" => "PAXG", "type" => "coin"},
            {"id" => "QTUM", "type" => "coin"},
            {"id" => "SC", "type" => "coin"},
            {"id" => "USDT", "type" => "coin"},
            {"id" => "WAVES", "type" => "coin"},
            {"id" => "ETC", "type" => "coin"},
            {"id" => "ETH", "type" => "coin"},
            {"id" => "LTC", "type" => "coin"},
            {"id" => "MLN", "type" => "coin"},
            {"id" => "REP", "type" => "coin"},
            {"id" => "XTZ", "type" => "coin"},
            {"id" => "XTZ.S", "type" => "coin"},
            {"id" => "XBT", "type" => "coin"},
            {"id" => "XDG", "type" => "coin"},
            {"id" => "XLM", "type" => "coin"},
            {"id" => "XMR", "type" => "coin"},
            {"id" => "XRP", "type" => "coin"},
            {"id" => "ZEC", "type" => "coin"},
            {"id" => "CAD", "type" => "coin"},
            {"id" => "EUR", "type" => "coin"},
            {"id" => "GBP", "type" => "coin"},
            {"id" => "JPY", "type" => "coin"},
            {"id" => "USD", "type" => "coin"}
          ]
        )
      end
    end
  end

  context "private endpoints" do
    include_context "kraken private"

    let(:exchange_config) do
      {
        "driver" => "kraken",
        "key"    => "abskdjfhksdjfhksjdfhksdjfhksjdhfksjdfhksdjfhksjdfhksjdfh",
        "secret" => "abcdefsdlksjdflksdjflskdjflskdjflskdjflskdjflskdjflskdjflskdjflskdfjslkdjfksjdfhksjdxz=="
      }
    end

    context "get_balances" do
      it "returns the list of account assets balances" do
        expect(kraken.get_balances).to eq(
          [
            {"currency" => "ZUSD", "free" => 0, "locked" => 0, "total" => 100.0000.to_d},
            {"currency" => "ZEUR", "free" => 0, "locked" => 0, "total" => 0.0000.to_d},
            {"currency" => "XXBT", "free" => 0, "locked" => 0, "total" => 10.3341681147.to_d},
            {"currency" => "XXRP", "free" => 0, "locked" => 0, "total" => 69.94654290.to_d},
            {"currency" => "XLTC", "free" => 0, "locked" => 0, "total" => 4.2315050300.to_d},
            {"currency" => "XNMC", "free" => 0, "locked" => 0, "total" => 0.0000000000.to_d},
            {"currency" => "XXDG", "free" => 0, "locked" => 0, "total" => 605.00000000.to_d},
            {"currency" => "XXLM", "free" => 0, "locked" => 0, "total" => 0.00000262.to_d},
            {"currency" => "XETH", "free" => 0, "locked" => 0, "total" => 0.0000000100.to_d},
            {"currency" => "XETC", "free" => 0, "locked" => 0, "total" => 0.0000000000.to_d},
            {"currency" => "XZEC", "free" => 0, "locked" => 0, "total" => 1.0000000000.to_d},
            {"currency" => "XXMR", "free" => 0, "locked" => 0, "total" => 21.4354237300.to_d},
            {"currency" => "USDT", "free" => 0, "locked" => 0, "total" => 0.00007280.to_d},
            {"currency" => "DASH", "free" => 0, "locked" => 0, "total" => 0.1324000000.to_d},
            {"currency" => "BCH", "free" => 0, "locked" => 0, "total" => 0.1032644153.to_d},
            {"currency" => "BSV", "free" => 0, "locked" => 0, "total" => 0.0000000000.to_d}
          ]
        )
      end
    end

    context "fetch_openorders" do
      it "returns the list of open orders" do
        expect(kraken.fetch_openorders("XRPUSD")).to eq(
          [
            ::Arke::Order.new("XRPUSD", 0.22, 100, :sell, :limit, "O7FHIE-CPMCK-65GSWL")
          ]
        )
      end
    end

    context "create_order" do
      it "creates an order" do
        order = ::Arke::Order.new("XRPUSD", 0.22, 100, :sell, :limit)
        body = "pair=XRPUSD&type=sell&volume=100.000000&price=0.220000&ordertype=limit&nonce=1576353032322571"
        kraken.create_order(order)
        expect(WebMock).to have_requested(:post, "https://api.kraken.com/0/private/AddOrder")
          .with(body: body).once
      end
    end

    context "stop_order" do
      it "cancels an order" do
        order = ::Arke::Order.new(nil, nil, nil, nil, nil, "O7FHIE-CPMCK-65GSWL")
        body = "txid=O7FHIE-CPMCK-65GSWL&nonce=1576353032322571"
        kraken.stop_order(order)
        expect(WebMock).to have_requested(:post, "https://api.kraken.com/0/private/CancelOrder")
          .with(body: body).once
      end
    end

    context "get_deposit_address" do
      it "retrive deposit address for a currency" do
        expect(kraken.get_deposit_address("XMR")).to eq(
          "address" => "4GdoN7NCTi8a5gZug7PrwZNKjvHFmKeV11L6pNJPgj5QNEHsN6eeX3DaAQFwZ1ufD4LYCZKArktt113W7QjWvA8CWCGXif9XanyK5UE4ab (exp 0)\n" \
          "            4GdoN7NCTi8a5gZug7PrwZNKjvHFmKeV11L6pNJPgj5QNEHsN6eeX3DaAQFwZ1ufD4LYCZKArktt113W7QjWvA8CW7BzpuJfhzGFR7RMuV (exp 0)"
        )
        body = "asset=XMR&nonce=1576353032322571"
        expect(WebMock).to have_requested(:post, "https://api.kraken.com/0/private/DepositMethods")
          .with(body: body).once
      end
    end
  end
end
