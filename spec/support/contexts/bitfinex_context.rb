# frozen_string_literal: true

shared_context "mocked bitfinex" do
  before(:each) do
    @authorized_api_key = "Uwg8wqlxueiLCsbTXjlogviL8hdd60"
    authorized_headers = {"x-bfx-apikey" => @authorized_api_key}

    stub_request(:post, "https://api.bitfinex.com/v1/balances")
      .to_return(status: 401, body: {"message"=>"Could not find a key matching the given X-BFX-APIKEY."}.to_json, headers: {"content-type" => "application/json;charset=utf-8"})

    stub_request(:get, "https://api-pub.bitfinex.com/v2/candles/trade:5m:tETHUSD/hist")
      .to_return(status: 200,
        body: [
          [1573123020000,186,186,186,186,37.68113751],
          [1573122960000,186,186,186,186,21.09442441],
          [1573122900000,185.83,186,186,185.83,58.82140792],
          [1573122840000,185.82,185.83,185.83,185.82,4.74146302],
          [1573122780000,185.82,185.82,185.82,185.82,0.07885584]
        ].to_json,
        headers: {"content-type" => "application/json;charset=utf-8"}
      )

    stub_request(:get, "https://api-pub.bitfinex.com/v2/candles/trade:5m:tETHUSD/last")
      .to_return(status: 200,
        body: [1573122840000,185.82,185.82,185.82,185.82,4.24897052].to_json,
        headers: {"content-type" => "application/json;charset=utf-8"}
      )

    stub_request(:post, "https://api.bitfinex.com/v1/order/new")
      .with(headers: authorized_headers)
      .to_return(status: 200,
      body: {
        "id":                  448_364_249,
        "symbol":              "ethusd",
        "exchange":            "bitfinex",
        "price":               "135.84",
        "avg_execution_price": "0.0",
        "side":                "buy",
        "type":                "exchange limit",
        "timestamp":           "1444272165.252370982",
        "is_live":             true,
        "is_cancelled":        false,
        "is_hidden":           false,
        "was_forced":          false,
        "original_amount":     "6.62227",
        "remaining_amount":    "6.62227",
        "executed_amount":     "0.0",
        "order_id":            448_364_249
      }.to_json, headers: {"content-type" => "application/json;charset=utf-8"})

    stub_request(:post, "https://api.bitfinex.com/v1/orders")
      .with(headers: authorized_headers)
      .to_return(status: 200,
      body:
        [{
          "id":                  123,
          "symbol":              "ethusd",
          "exchange":            "bitfinex",
          "price":               "0.02",
          "avg_execution_price": "0.0",
          "side":                "buy",
          "type":                "exchange limit",
          "timestamp":           "1444276597.0",
          "is_live":             true,
          "is_cancelled":        false,
          "is_hidden":           false,
          "was_forced":          false,
          "original_amount":     "0.3",
          "remaining_amount":    "0.2",
          "executed_amount":     "0.1"
        },
         {
           "id":                  124,
           "symbol":              "ethusd",
           "exchange":            "bitfinex",
           "price":               "0.02",
           "avg_execution_price": "0.0",
           "side":                "buy",
           "type":                "exchange limit",
           "timestamp":           "1444276597.0",
           "is_live":             false,
           "is_cancelled":        false,
           "is_hidden":           false,
           "was_forced":          false,
           "original_amount":     "0.3",
           "remaining_amount":    "0.2",
           "executed_amount":     "0.1"
         },
         {
           "id":                  125,
           "symbol":              "btcusd",
           "exchange":            "bitfinex",
           "price":               "0.02",
           "avg_execution_price": "0.0",
           "side":                "buy",
           "type":                "exchange limit",
           "timestamp":           "1444276597.0",
           "is_live":             true,
           "is_cancelled":        false,
           "is_hidden":           false,
           "was_forced":          false,
           "original_amount":     "0.3",
           "remaining_amount":    "0.2",
           "executed_amount":     "0.1"
         }].to_json, headers: {
           "content-type" => "application/json;charset=utf-8"
         })

    stub_request(:post, "https://api.bitfinex.com/v1/balances")
      .with(headers: authorized_headers)
      .to_return(status: 200,
      body: [
        {
          "type":      "deposit",
          "currency":  "eth",
          "amount":    "100.12",
          "available": "100.12"
        }, {
          "type":      "deposit",
          "currency":  "usd",
          "amount":    "110",
          "available": "100"
        }
      ].to_json, headers: {"content-type" => "application/json;charset=utf-8"})
  end
end
