# frozen_string_literal: true

shared_context "kraken public" do
  before(:each) do
    stub_request(:get, "https://api.kraken.com/0/public/AssetPairs")
      .to_return(
        status:  200,
        body:    file_fixture("kraken/assetpairs.json").read,
        headers: {
          "content-type" => "application/json; charset=utf-8"
        }
      )

    stub_request(:get, "https://api.kraken.com/0/public/Assets")
      .to_return(
        status:  200,
        body:    file_fixture("kraken/assets.json").read,
        headers: {
          "content-type" => "application/json; charset=utf-8"
        }
      )

    stub_request(:get, "https://api.kraken.com/0/public/Depth?pair=XBTUSD")
      .to_return(
        status:  200,
        body:    file_fixture("kraken/depth-XBTUSD.json").read,
        headers: {
          "content-type" => "application/json; charset=utf-8"
        }
      )
  end
end

shared_context "kraken private" do
  before(:each) do
    allow(kraken).to receive(:generate_nonce) { 1_576_353_032_322_571 }
    auth_headers = {
      "Api-Key"      => "abskdjfhksdjfhksjdfhksdjfhksjdhfksjdfhksdjfhksjdfhksjdfh",
      # "Api-Sign"     => "YB2Ha1dnpSYxUCXH5rfYl8t/TMK55djDeqoJ1UV9rVFFjCa2fykciIl45bucMQE7736ZqWm1R2+I3pT4QUIKVQ==",
      "Content-Type" => "application/x-www-form-urlencoded"
    }

    stub_request(:post, "https://api.kraken.com/0/private/Balance")
      .with(headers: auth_headers)
      .to_return(
        status:  200,
        body:    file_fixture("kraken/balances.json").read,
        headers: {
          "content-type" => "application/json; charset=utf-8"
        }
      )

    stub_request(:post, "https://api.kraken.com/0/private/AddOrder")
      .with(headers: auth_headers)
      .to_return(
        status:  200,
        body:    {"error" => [], "result" => {"descr" => {"order"=>"sell 100.00000000 XRPUSD @ limit 0.22000"}, "txid" => ["O6C6TP-PRPKI-2TCA7Y"]}}.to_json,
        headers: {
          "content-type" => "application/json; charset=utf-8"
        }
      )

    stub_request(:post, "https://api.kraken.com/0/private/CancelOrder")
      .with(headers: auth_headers)
      .to_return(
        status:  200,
        body:    {"error" => [], "result" => {"count"=>1}}.to_json,
        headers: {
          "content-type" => "application/json; charset=utf-8"
        }
      )

    stub_request(:post, "https://api.kraken.com/0/private/OpenOrders")
      .with(headers: auth_headers)
      .to_return(
        status:  200,
        body:    file_fixture("kraken/openorders.json").read,
        headers: {
          "content-type" => "application/json; charset=utf-8"
        }
      )

    stub_request(:post, "https://api.kraken.com/0/private/DepositMethods")
      .with(headers: auth_headers)
      .to_return(
        status:  200,
        body:    {
          "error"  => [],
          "result" => [
            {"method"      => "Monero",
             "limit"       => false,
             "fee"         => "0.0000000000",
             "gen-address" => true}
          ]
        }.to_json,
        headers: {
          "content-type" => "application/json; charset=utf-8"
        }
      )

    stub_request(:post, "https://api.kraken.com/0/private/DepositAddresses")
      .with(headers: auth_headers)
      .to_return(
        status:  200,
        body:    {
          "error"  => [],
          "result" => [
            {
              "address"  => "4GdoN7NCTi8a5gZug7PrwZNKjvHFmKeV11L6pNJPgj5QNEHsN6eeX3DaAQFwZ1ufD4LYCZKArktt113W7QjWvA8CWCGXif9XanyK5UE4ab",
              "expiretm" => "0"
            },
            {
              "address"  => "4GdoN7NCTi8a5gZug7PrwZNKjvHFmKeV11L6pNJPgj5QNEHsN6eeX3DaAQFwZ1ufD4LYCZKArktt113W7QjWvA8CW7BzpuJfhzGFR7RMuV",
              "expiretm" => "0"
            }
          ]
        }.to_json,
        headers: {
          "content-type" => "application/json; charset=utf-8"
        }
      )
  end
end
