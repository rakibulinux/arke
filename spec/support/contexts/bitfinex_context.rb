# frozen_string_literal: true

shared_context "mocked bitfinex" do
  before(:each) do
    @authorized_api_key = "Uwg8wqlxueiLCsbTXjlogviL8hdd60"
    authorized_headers = {"x-bfx-apikey" => @authorized_api_key}

    stub_request(:post, "https://api.bitfinex.com/v1/balances")
      .to_return(status: 401, body: {"message"=>"Could not find a key matching the given X-BFX-APIKEY."}.to_json, headers: {"content-type" => "application/json;charset=utf-8"})

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

    stub_request(:get, "https://api.bitfinex.com/v1/symbols_details")
      .to_return(status: 200,
    body: [
      {
        "pair":               "btcusd",
        "price_precision":    5,
        "initial_margin":     "30.0",
        "minimum_margin":     "15.0",
        "maximum_order_size": "2000.0",
        "minimum_order_size": "0.0006",
        "expiration":         "NA",
        "margin":             true
      },
      {
        "pair":               "btcust",
        "price_precision":    5,
        "initial_margin":     "30.0",
        "minimum_margin":     "15.0",
        "maximum_order_size": "2000.0",
        "minimum_order_size": "0.0006",
        "expiration":         "NA",
        "margin":             true
      },
      {
        "pair":               "ltcusd",
        "price_precision":    5,
        "initial_margin":     "30.0",
        "minimum_margin":     "15.0",
        "maximum_order_size": "5000.0",
        "minimum_order_size": "0.2",
        "expiration":         "NA",
        "margin":             true
      },
      {
        "pair":               "ethusd",
        "price_precision":    5,
        "initial_margin":     "30.0",
        "minimum_margin":     "15.0",
        "maximum_order_size": "5000.0",
        "minimum_order_size": "0.04",
        "expiration":         "NA",
        "margin":             true
      },
      {
        "pair":               "cnh:cnht",
        "price_precision":    5,
        "initial_margin":     "30.0",
        "minimum_margin":     "15.0",
        "maximum_order_size": "500000.0",
        "minimum_order_size": "6.0",
        "expiration":         "NA",
        "margin":             false
      }
    ].to_json, headers: {"content-type" => "application/json;charset=utf-8"})
  end
end
