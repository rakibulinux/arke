# frozen_string_literal: true

markets = [
  {
    "id"               => "ethbtc",
    "name"             => "ETH/BTC",
    "base_unit"        => "eth",
    "quote_unit"       => "btc",
    "min_price"        => "0.001",
    "max_price"        => "0.3",
    "min_amount"       => "0.025",
    "amount_precision" => 4,
    "price_precision"  => 6,
    "state"            => "enabled"
  },
  {
    "id"               => "btcusd",
    "name"             => "BTC/USD",
    "base_unit"        => "btc",
    "quote_unit"       => "usd",
    "min_price"        => "100.0",
    "max_price"        => "100000.0",
    "min_amount"       => "0.0005",
    "amount_precision" => 6,
    "price_precision"  => 2,
    "state"            => "enabled"
  },
  {
    "id"               => "ethusd",
    "name"             => "ETH/USD",
    "base_unit"        => "eth",
    "quote_unit"       => "usd",
    "min_price"        => "100.0",
    "max_price"        => "100000.0",
    "min_amount"       => "0.0005",
    "amount_precision" => 4,
    "price_precision"  => 2,
    "state"            => "enabled"
  }
]

shared_context "mocked rubykube" do
  before(:each) do
    # TODO: find better way to store it (let is not accassible inside before)
    @authorized_api_key = "3107c98eb442e4135541d434410aaaa6"
    authorized_header = {"X-Auth-Apikey"=> @authorized_api_key}

    # non-authorized requests

    stub_request(:post, %r{peatio/market/orders$})
      .to_return(status: 403, body: "", headers: {})

    stub_request(:get, %r{peatio/market/orders})
      .to_return(status: 403, body: "", headers: {})

    stub_request(:get, %r{peatio/account/balances$})
      .to_return(status: 403, body: "", headers: {})

    # authorized requests

    stub_request(:get, %r{peatio/public/timestamp$})
      .with(headers: authorized_header)
      .to_return(status: 200, body: "", headers: {})

    stub_request(:post, %r{peatio/market/orders$})
      .with(headers: authorized_header)
      .to_return(status: 201, body: {id: Random.rand(1...1000)}.to_json, headers: {})

    stub_request(:post, %r{peatio/market/orders/cancel$})
      .with(headers: authorized_header)
      .to_return(status: 201, body: "", headers: {})

    stub_request(:post, %r{peatio/market/orders/\d+/cancel$})
      .with(headers: authorized_header)
      .to_return(status: 201, body: "", headers: {})

    stub_request(:get, %r{peatio/market/orders})
      .with(headers: authorized_header)
      .to_return(
        status:  200,
        body:    [
          {"id" => 4, "side" => "sell", "ord_type" => "limit", "price" => "138.87", "avg_price" => "0.0", "state" => "wait", "market" => "fthusd", "created_at" => "2019-05-15T12:18:42+02:00", "updated_at" => "2019-05-15T12:18:42+02:00", "origin_volume" => "2.0", "remaining_volume" => "2.0", "executed_volume" => "0.0", "trades_count" => 0},
          {"id" => 3, "side" => "buy", "ord_type" => "limit", "price" => "233.98", "avg_price" => "0.0", "state" => "wait", "market" => "fthusd", "created_at" => "2019-05-15T12:18:37+02:00", "updated_at" => "2019-05-15T12:18:37+02:00", "origin_volume" => "4.68", "remaining_volume" => "4.68", "executed_volume" => "0.0", "trades_count" => 0},
          {"id" => 2, "side" => "sell", "ord_type" => "limit", "price" => "138.87", "avg_price" => "0.0", "state" => "wait", "market" => "fthusd", "created_at" => "2019-05-15T12:18:21+02:00", "updated_at" => "2019-05-15T12:18:21+02:00", "origin_volume" => "2.0", "remaining_volume" => "2.0", "executed_volume" => "0.0", "trades_count" => 0},
          {"id" => 1, "side" => "buy", "ord_type" => "limit", "price" => "138.76", "avg_price" => "0.0", "state" => "wait", "market" => "fthusd", "created_at" => "2019-05-15T12:18:04+02:00", "updated_at" => "2019-05-15T12:18:04+02:00", "origin_volume" => "0.17", "remaining_volume" => "0.17", "executed_volume" => "0.0", "trades_count" => 0}
        ].to_json,
        headers: {Total: 4}
      )

    stub_request(:get, %r{peatio/account/balances$})
      .with(headers: authorized_header)
      .to_return(
        status:  200,
        body:    [
          {"currency" => "eth", "balance" => "0.0", "locked" => "0.0"},
          {"currency" => "fth", "balance" => "1000000.0", "locked" => "0.0"},
          {"currency" => "trst", "balance" => "0.0", "locked" => "0.0"},
          {"currency" => "usd", "balance" => "999990.0", "locked" => "10.0"}
        ].to_json,
        headers: {}
      )

    stub_request(:get, %r{peatio/public/markets$})
      .to_return(
        status:  200,
        body:    markets.to_json,
        headers: {}
      )
  end
end

shared_context "mocked finex" do
  before(:each) do
    @authorized_api_key = "3107c98eb442e4135541d434410aaaa6"
    authorized_header = {"X-Auth-Apikey"=> @authorized_api_key}

    stub_request(:post, %r{finex/market/orders$})
      .with(headers: authorized_header)
      .to_return(status: 201, body: {}.to_json, headers: {})

    stub_request(:get, %r{peatio/public/markets$})
      .to_return(
        status:  200,
        body:    markets.to_json,
        headers: {}
      )

    stub_request(:post, %r{finex/market/orders/\d+/cancel$})
      .with(headers: {"X-Auth-Apikey"=> @authorized_api_key})
      .to_return(
        status:  201,
        body:    {}.to_json,
        headers: {}
      )
  end
end
