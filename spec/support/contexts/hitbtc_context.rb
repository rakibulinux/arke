# frozen_string_literal: true

shared_context "mocked hitbtc" do
  before(:each) do
    authorized_headers = {
      "Authorization" => "Basic YWJjZGVmZ2hpamtsbTpza2hma3NqaGdrc2RqaGZrc2pkZmtqc2Rma3NqaGRrZnNq",
    }

    stub_request(:get, "https://api.hitbtc.com/api/2/trading/balance")
      .with(headers: authorized_headers)
      .to_return(status:  200,
                 body:    [
                   {
                     "currency":  "ETH",
                     "available": "10.000000000",
                     "reserved":  "0.560000000"
                   },
                   {
                     "currency":  "USD",
                     "available": "0.010205869",
                     "reserved":  "0"
                   }
                 ].to_json,
                 headers: {"content-type" => "application/json"})

    stub_request(:get, "https://api.hitbtc.com/api/2/public/orderbook/ETHUSD")
      .with(headers: authorized_headers)
      .to_return(status:  200,
                 body:    {
                   "ask":       [
                     {
                       "price": "0.046002",
                       "size":  "0.088"
                     },
                     {
                       "price": "0.046800",
                       "size":  "0.200"
                     }
                   ],
                   "bid":       [
                     {
                       "price": "0.046001",
                       "size":  "0.005"
                     },
                     {
                       "price": "0.046000",
                       "size":  "0.200"
                     }
                   ],
                   "timestamp": "2018-11-19T05:00:28.193Z"
                 }.to_json,
                 headers: {"content-type" => "application/json"})

    stub_request(:get, "https://api.hitbtc.com/api/2/public/symbol")
      .with(headers: authorized_headers)
      .to_return(status:  200,
                 body:    [
                   {
                     "id":                   "ETHBTC",
                     "baseCurrency":         "ETH",
                     "quoteCurrency":        "BTC",
                     "quantityIncrement":    "0.001",
                     "tickSize":             "0.000001",
                     "takeLiquidityRate":    "0.001",
                     "provideLiquidityRate": "-0.0001",
                     "feeCurrency":          "BTC"
                   },
                   {
                     "id":                   "ETHUSD",
                     "baseCurrency":         "ETH",
                     "quoteCurrency":        "USD",
                     "quantityIncrement":    "0.001",
                     "tickSize":             "0.000001",
                     "takeLiquidityRate":    "0.001",
                     "provideLiquidityRate": "-0.0001",
                     "feeCurrency":          "USD"
                   },
                 ].to_json,
                 headers: {"content-type" => "application/json"})

    stub_request(:post, "https://api.hitbtc.com/api/2/order")
      .with(headers: authorized_headers)
      .to_return(status:  200,
                 body:    {
                   "id":            0,
                   "clientOrderId": "d8574207d9e3b16a4a5511753eeef175",
                   "symbol":        "ETHBTC",
                   "side":          "sell",
                   "status":        "new",
                   "type":          "limit",
                   "timeInForce":   "GTC",
                   "quantity":      "0.063",
                   "price":         "0.046016",
                   "cumQuantity":   "0.000",
                   "postOnly":      false,
                   "createdAt":     "2017-05-15T17:01:05.092Z",
                   "updatedAt":     "2017-05-15T17:01:05.092Z"
                 }.to_json,
                 headers: {"content-type" => "application/json"})
  end
end
