# frozen_string_literal: true

describe Arke::Exchange::Valr do
  let(:exchange_config) do
    {
      "driver" => "valr",
      "host"   => "api.valr.com",
      "key"    => "abcdef",
      "secret" => "4961b74efac86b25cce8fbe4c9811c4c7a787b7a5996660afcc2e287ad864363",
    }
  end
  let(:market_id) { "ethusd" }
  let(:market) { Arke::Market.new(market_id, valr) }
  let(:order) { Arke::Order.new("ethusd", 1, 1, :buy) }
  let(:valr) { Arke::Exchange::Valr.new(exchange_config) }

  context "authenticated requests" do
    it "signs request with secret" do
      ts = "1558017528946"
      body = '{"customerOrderId":"ORDER-000001","pair":"BTCZAR","side":"BUY","quoteAmount":"80000"}'
      path = "/v1/orders/market"
      verb = "post"
      exp_signature = "be97d4cd9077a9eea7c4e199ddcfd87408cb638f2ec2f7f74dd44aef70a49fdc49960fd5de9b8b2845dc4a38b4fc7e56ef08f042a3c78a3af9aed23ca80822e8"
      signature = valr.sign(ts, verb, path, body)
      expect(signature).to eq(exp_signature)
    end
  end

  context "public endpoints" do
    include_context "valr public"

    context "currencies" do
      it do
        expect(valr.currencies).to eq(
          [{
            "symbol"    => "R",
            "isActive"  => true,
            "shortName" => "ZAR",
            "longName"  => "Rand"
          },
           {
             "symbol"    => "BTC",
             "isActive"  => true,
             "shortName" => "BTC",
             "longName"  => "Bitcoin"
           },
           {
             "symbol"    => "ETH",
             "isActive"  => true,
             "shortName" => "ETH",
             "longName"  => "Ethereum"
           }]
        )
      end
    end

    context "orderbook" do
      it do
        ob = valr.update_orderbook("btczar")
        expect(ob[:buy].to_hash).to eq(
          0.1e1.to_d    => 0.8027437e-1.to_d,
          0.81e4.to_d   => 0.1e0.to_d,
          0.82e4.to_d   => 0.3e0.to_d,
          0.84e4.to_d   => 0.1e0.to_d,
          0.85e4.to_d   => 0.1e0.to_d,
          0.86e4.to_d   => 0.1e0.to_d,
          0.87e4.to_d   => 0.1e0.to_d,
          0.8801e4.to_d => 0.2e0.to_d,
          0.8802e4.to_d => 0.1e0.to_d,
          0.88e4.to_d   => 0.1e0.to_d,
          0.8e4.to_d    => 0.1e0.to_d
        )
        expect(ob[:sell].to_hash).to eq(
          0.11606e5.to_d => 0.1e0.to_d,
          0.14e5.to_d    => 0.67713484e0.to_d,
          0.15e5.to_d    => 0.1e1.to_d,
          0.16e5.to_d    => 0.1e1.to_d,
          0.17e5.to_d    => 0.1e1.to_d,
          0.18e5.to_d    => 0.1e1.to_d,
          0.19e5.to_d    => 0.1e1.to_d,
          0.1e5.to_d     => 0.793789e0.to_d,
          0.9e4.to_d     => 0.101e0.to_d
        )
      end
    end

    context "market_config" do
      it do
        expect(valr.market_config("btczar")).to eq(
          "amount_precision" => 8,
          "base_unit"        => "BTC",
          "id"               => "BTCZAR",
          "min_amount"       => 0.0001,
          "price_precision"  => 0,
          "quote_unit"       => "ZAR"
        )
        expect(valr.market_config("zecbtc")).to eq(
          "amount_precision" => 8,
          "base_unit"        => "ZEC",
          "id"               => "ZECBTC",
          "min_amount"       => 0.0521,
          "price_precision"  => 8,
          "quote_unit"       => "BTC"
        )
      end
    end
  end

  context "private endpoints" do
    include_context "valr public"
    include_context "valr private"

    context "get_balances" do
      it do
        expect(valr.get_balances).to eq(
          [
            {"currency" => "ETH", "free" => "0.01626594758".to_d, "locked" => "0.49".to_d, "total" => "0.50626594758".to_d},
            {"currency" => "XEM", "free" => 0, "locked" => 0, "total" => 0}
          ]
        )
      end
    end

    context "fetch_openorders" do
      it do
        expect(valr.fetch_openorders("btczar")).to eq(
          [
            Arke::Order.new("BTCZAR", 100_000, 0.1, :sell, "limit", "da99bd40-41a2-42dd-8601-bc99edc31df2"),
          ]
        )
        expect(valr.fetch_openorders("ethzar")).to eq(
          [
            Arke::Order.new("ETHZAR", 150_000, 0.07465, :sell, "limit", "b53f4f12-f156-4623-81fe-98425760d417"),
          ]
        )
      end
    end

    context "get_deposit_address" do
      it do
        expect(valr.get_deposit_address("eth")).to eq(
          "currency" => "ETH",
          "address"  => "0xA7Fae2Fd50886b962d46FF4280f595A3982aeAa5"
        )
      end
    end

    context "stop_order" do
      it do
        stub_request(:delete, "https://api.valr.com/v1/orders/order")
        .with(
          body: "{\"orderId\":\"da99bd40-41a2-42dd-8601-bc99edc31df2\",\"pair\":\"BTCZAR\"}",
          headers: {
            "Accept"           => "application/json",
            "User-Agent"       => "Faraday v0.15.4",
            "X-Valr-Api-Key"   => "abcdef",
            "X-Valr-Signature" => "6a2c253885eff940bc320f327477228ba7c492ce15e93393a84cc79aa8ab46d9aff04b981aaa31163d873b149b76f7492384f8952715ad25f6daf4730d96d1e5",
            "X-Valr-Timestamp" => "1576353032322571"
          }
        )
      .to_return(
          status:  202
        )
        valr.stop_order(Arke::Order.new("BTCZAR", 100_000, 0.1, :sell, "limit", "da99bd40-41a2-42dd-8601-bc99edc31df2"))
      end
    end

    context "create_order" do
      it "creates a limit order" do
        stub_request(:post, "https://api.valr.com/v1/orders/limit")
          .with(
            body:    "{\"market\":\"ETHZAR\",\"side\":\"SELL\",\"quantity\":\"0.074650\",\"price\":\"150000.000000\"}",
            headers: {
              "Accept"           => "application/json",
              "User-Agent"       => "Faraday v0.15.4",
              "X-Valr-Api-Key"   => "abcdef",
              "X-Valr-Signature" => "0a77882b85ff31d17d931b64e48069446c2bbf75a13671d38b3f9e66df48d5c4cc8a4db7cd18c65f1af86f7001ed7633abe0ec45c994ca6fca1ddb069d16d783",
              "X-Valr-Timestamp" => "1576353032322571"
            }
          )
          .to_return(
            status:  202,
            body:    '{"id":"558f5e0a-ffd1-46dd-8fae-763d93fa2f25"}',
            headers: {
              "Content-Type" => "application/json"
            }
          )

        o = valr.create_order(Arke::Order.new("ETHZAR", 150_000, 0.07465, :sell))
        expect(o.id).to eq("558f5e0a-ffd1-46dd-8fae-763d93fa2f25")
      end

      it "creates a market order sell" do
        stub_request(:post, "https://api.valr.com/v1/orders/market")
          .with(
            body:    "{\"market\":\"ETHZAR\",\"side\":\"SELL\",\"baseAmount\":\"0.074650\"}",
            headers: {
              "Accept"           => "application/json",
              "User-Agent"       => "Faraday v0.15.4",
              "X-Valr-Api-Key"   => "abcdef",
              "X-Valr-Signature" => "846ae977cd75d45aceb5570eb8090ef2dc17c0ac0b71954680c7e3dd29fb2cf3e9903d0f3f7a5e2c94a3a3c8e59626ae90a7824e928840802a7245feae277600",
              "X-Valr-Timestamp" => "1576353032322571"
            }
          )
          .to_return(
            status:  202,
            body:    '{"id":"558f5e0a-ffd1-46dd-8fae-763d93fa2f25"}',
            headers: {
              "Content-Type" => "application/json"
            }
          )
        o = valr.create_order(Arke::Order.new("ETHZAR", 0, 0.07465, :sell, "market"))
        expect(o.id).to eq("558f5e0a-ffd1-46dd-8fae-763d93fa2f25")
      end

      it "creates a market order buy" do
        stub_request(:post, "https://api.valr.com/v1/orders/market")
          .with(
            body:    "{\"market\":\"ETHZAR\",\"side\":\"BUY\",\"baseAmount\":\"0.074650\"}",
            headers: {
              "Accept"           => "application/json",
              "User-Agent"       => "Faraday v0.15.4",
              "X-Valr-Api-Key"   => "abcdef",
              "X-Valr-Signature" => "9d1a0f556f7517f97b4ea364f8ec77e0ac2b51c3832f2dfb0680cb1b2ad700841273f1059182ac3d77e415c31591114bafcb7035c1482bef376c64dd68b8eb80",
              "X-Valr-Timestamp" => "1576353032322571"
            }
          )
          .to_return(
            status:  202,
            body:    '{"id":"558f5e0a-ffd1-46dd-8fae-763d93fa2f25"}',
            headers: {
              "Content-Type" => "application/json"
            }
          )
        o = valr.create_order(Arke::Order.new("ETHZAR", 150_000, 0.07465, :buy, "market"))
        expect(o.id).to eq("558f5e0a-ffd1-46dd-8fae-763d93fa2f25")
      end
    end
  end
end
