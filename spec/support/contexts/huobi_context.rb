# frozen_string_literal: true

shared_context "mocked huobi" do
  before(:each) do
    stub_request(:get, "https://api.huobi.pro/market/depth?symbol=ethusdt&type=step0")
      .to_return(
        status:  200,
        body:    {
          "tick": {
            "version": 31_615_842_081,
            "ts":      1_489_464_585_407,
            "bids":    [
              ["135.84000000", "6.62227000"],
              ["135.85000000", "0.57176000"],
              ["135.87000000", "36.43875000"],
            ],
            "asks":    [
              ["135.91000000", "0.00070000"],
              ["135.93000000", "8.00000000"],
              ["135.95000000", "1.11699000"],
            ]
          }
        }.to_json,
        headers: {}
      )

    stub_request(:get, "https://api.huobi.pro/v1/common/symbols")
      .to_return(
        status:  200,
        body:    {
          "status": "ok",
          "data":   [
            {
              "base-currency":               "btc",
              "quote-currency":              "usdt",
              "price-precision":             2,
              "amount-precision":            6,
              "symbol-partition":            "main",
              "symbol":                      "btcusdt",
              "state":                       "online",
              "value-precision":             8,
              "min-order-amt":               0.0001,
              "max-order-amt":               1000,
              "min-order-value":             1,
              "leverage-ratio":              5,
              "super-margin-leverage-ratio": 3
            },
            {
              "base-currency":               "eth",
              "quote-currency":              "usdt",
              "price-precision":             2,
              "amount-precision":            4,
              "symbol-partition":            "main",
              "symbol":                      "ethusdt",
              "state":                       "online",
              "value-precision":             8,
              "min-order-amt":               0.001,
              "max-order-amt":               10_000,
              "min-order-value":             1,
              "leverage-ratio":              5,
              "super-margin-leverage-ratio": 3
            },
            {
              "base-currency":    "mtx",
              "quote-currency":   "eth",
              "price-precision":  8,
              "amount-precision": 2,
              "symbol-partition": "innovation",
              "symbol":           "mtxeth",
              "state":            "online",
              "value-precision":  8,
              "min-order-amt":    0.1,
              "max-order-amt":    1_000_000,
              "min-order-value":  0.001
            },
            {
              "base-currency":    "zla",
              "quote-currency":   "btc",
              "price-precision":  8,
              "amount-precision": 2,
              "symbol-partition": "innovation",
              "symbol":           "zlabtc",
              "state":            "online",
              "value-precision":  8,
              "min-order-amt":    0.1,
              "max-order-amt":    1_000_000,
              "min-order-value":  0.0001
            },
            {
              "base-currency":    "wtc",
              "quote-currency":   "usdt",
              "price-precision":  4,
              "amount-precision": 4,
              "symbol-partition": "innovation",
              "symbol":           "wtcusdt",
              "state":            "online",
              "value-precision":  8,
              "min-order-amt":    0.1,
              "max-order-amt":    300_000,
              "min-order-value":  1
            },
          ]
        }.to_json,
        headers: {
          "content-type" => "application/json;charset=utf-8"
        }
      )

    stub_request(:get, build_url("/v1/account/accounts", "GET"))
      .to_return(status: 200, body: {
        "data": [
          {
            "id":      123,
            "type":    "spot",
            "state":   "working",
            "user-id": 1000
          },
        ]
      }.to_json, headers: {
        "content-type" => "application/json;charset=utf-8"
      })

    stub_request(:get, build_url("/v1/account/accounts/123/balance", "GET"))
      .to_return(status:  200,
                 body:    {
                   "data": {
                     "id":    123,
                     "type":  "spot",
                     "state": "working",
                     "list":  [
                       {
                         "currency": "usdt",
                         "type":     "trade",
                         "balance":  "123.0"
                       },
                       {
                         "currency": "usdt",
                         "type":     "frozen",
                         "balance":  "32.0"
                       },
                       {
                         "currency": "eth",
                         "type":     "trade",
                         "balance":  "499999894616.1302471000"
                       }
                     ],
                   }
                 }.to_json,
                 headers: {
                   "content-type" => "application/json;charset=utf-8"
                 })

    stub_request(:post, build_url("/v1/order/orders/place", "POST"))
      .to_return(status:  200,
                 body:    {
                   "data": "59378"
                 }.to_json,
                 headers: {
                   "content-type" => "application/json;charset=utf-8"
                 })

    stub_request(:get, build_url("/v1/order/openOrders", "GET"))
      .to_return(status:  200,
                 body:    {
                   "data": [
                     {
                       "id":                 42,
                       "symbol":             "ethusdt",
                       "account-id":         123,
                       "amount":             "1.000000000000000000",
                       "price":              "0.453000000000000000",
                       "created-at":         1_530_604_762_277,
                       "type":               "sell-limit",
                       "filled-amount":      "0.0",
                       "filled-cash-amount": "0.0",
                       "filled-fees":        "0.0",
                       "source":             "web",
                       "state":              "submitted"
                     },
                     {
                       "id":                 43,
                       "symbol":             "ethusdt",
                       "account-id":         123,
                       "amount":             "0.500000000000000000",
                       "price":              "0.452000000000000000",
                       "created-at":         1_530_604_762_277,
                       "type":               "buy-limit",
                       "filled-amount":      "0.2",
                       "filled-cash-amount": "0.0",
                       "filled-fees":        "0.0",
                       "source":             "web",
                       "state":              "submitted"
                     }
                   ]
                 }.to_json,
                 headers: {
                   "content-type" => "application/json;charset=utf-8"
                 })
  end

  def build_url(path, method)
    api_key = "Uwg8wqlxueiLCsbTXjlogviL8hdd60"
    secret = "OwpadzSYOSkzweoJkjPrFeVgjOwOuxVHk8FXIlffdWw"

    h = {
      AccessKeyId:      api_key,
      SignatureMethod:  "HmacSHA256",
      SignatureVersion: 2,
      Timestamp:        Time.now.getutc.strftime("%Y-%m-%dT%H")
    }
    data = "#{method}\napi.huobi.pro\n#{path}\n#{Rack::Utils.build_query(hash_sort(h))}"
    h["Signature"] = Base64.encode64(OpenSSL::HMAC.digest("sha256", secret, data)).gsub("\n", "")
    url = "https://api.huobi.pro#{path}?#{Rack::Utils.build_query(h)}"
  end

  def hash_sort(ha)
    Hash[ha.sort_by {|key, _val| key }]
  end
end
