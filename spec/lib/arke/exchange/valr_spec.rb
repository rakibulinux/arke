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
  let(:pair) { Arke::Market.new(market_id, valr) }
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
          "min_amount"       => "0.0521".to_d,
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
            body:    "{\"pair\":\"ETHZAR\",\"side\":\"SELL\",\"quantity\":\"0.074650\",\"price\":\"150000.000000\"}",
            headers: {
              "Accept"           => "application/json",
              "X-Valr-Api-Key"   => "abcdef",
              "X-Valr-Signature" => "21d0e13adb241f9cb303eff248db3f5c60ad9d0d78afbdde50969a57ecc5f90105b7af974b89aa1dbff5f9eb4bf0b9b4bea04ca2149ad29724afa1f8f2215a2a",
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
            body:    "{\"pair\":\"ETHZAR\",\"side\":\"SELL\",\"baseAmount\":\"0.074650\"}",
            headers: {
              "Accept"           => "application/json",
              "X-Valr-Api-Key"   => "abcdef",
              "X-Valr-Signature" => "44a425a387709023ee8f843b84d5d7c3cc7b90792c50f47c56ce6f2c27de8786821917cceddc787502c1630ce5007f54b67df722be12a84a958610c5fc94c896",
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
            body:    "{\"pair\":\"ETHZAR\",\"side\":\"BUY\",\"baseAmount\":\"0.074650\"}",
            headers: {
              "Accept"           => "application/json",
              "X-Valr-Api-Key"   => "abcdef",
              "X-Valr-Signature" => "8b331540b0fc79b57f903291cc2898f3851ba3824a6cb6e96e0b3db0c87637c6889ce1bbbbff97e3bc40ee802f3127ea63882ca9ee1c5ac1b6ac5c371c12e669",
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
