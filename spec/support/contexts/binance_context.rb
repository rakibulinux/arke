# frozen_string_literal: true

shared_context "mocked binance" do
  before(:each) do
    @authorized_api_key = "Uwg8wqlxueiLCsbTXjlogviL8hdd60"
    authorized_headers = {"X-MBX-APIKEY" => @authorized_api_key}

    stub_request(:post, "https://api.binance.com/api/v3/order")
      .to_return(status: 401, body: "Unauthorized", headers: {})

    stub_request(:get, "https://api.binance.com/api/v1/depth?limit=1000&symbol=ETHUSDT")
      .to_return(
        status:  200,
        body:    {
          "lastUpdateId" => 320_927_259,
          "bids"         => [["135.87000000", "36.43875000", []], ["135.85000000", "0.57176000", []], ["135.84000000", "6.62227000", []]],
          "asks"         => [["135.91000000", "0.00070000", []], ["135.93000000", "8.00000000", []], ["135.95000000", "1.11699000", []]]
        }.to_json,
        headers: {
          "content-type" => "application/json;charset=utf-8",
        }
      )

    stub_request(:post, %r{https://api.binance.com/api/v3/order})
      .with(headers: authorized_headers)
      .to_return(status: 200, body: "", headers: {})

    stub_request(:get, "https://api.binance.com/api/v1/exchangeInfo")
      .to_return(
        status:  200,
        body:    {
          "timezone":        "UTC",
          "serverTime":      1_560_347_502_144,
          "rateLimits":
                             [{"rateLimitType": "REQUEST_WEIGHT", "interval": "MINUTE", "intervalNum": 1, "limit": 1200},
                              {"rateLimitType": "ORDERS", "interval": "SECOND", "intervalNum": 1, "limit": 10},
                              {"rateLimitType": "ORDERS", "interval": "DAY", "intervalNum": 1, "limit": 100_000}],
          "exchangeFilters": [],
          "symbols":
                             [{:symbol                 => "ETHUSDT",
                               :status                 => "TRADING",
                               :baseAsset              => "ETH",
                               "baseAssetPrecision"    => 8,
                               :quoteAsset             => "USDT",
                               :quotePrecision         => 8,
                               :orderTypes             => %w[LIMIT LIMIT_MAKER MARKET STOP_LOSS_LIMIT TAKE_PROFIT_LIMIT],
                               :icebergAllowed         => true,
                               :isSpotTradingAllowed   => true,
                               :isMarginTradingAllowed => true,
                               :filters                => [{"filterType": "PRICE_FILTER", "minPrice": "0.01000000", "maxPrice": "10000000.00000000", "tickSize": "0.01000000"},
                                                           {"filterType": "PERCENT_PRICE", "multiplierUp": "5", "multiplierDown": "0.2", "avgPriceMins": 5},
                                                           {"filterType": "LOT_SIZE", "minQty": "0.00001000", "maxQty": "10000000.00000000", "stepSize": "0.00001000"},
                                                           {"filterType": "MIN_NOTIONAL", "minNotional": "10.00000000", "applyToMarket": true, "avgPriceMins": 5},
                                                           {"filterType": "ICEBERG_PARTS", "limit": 10},
                                                           {"filterType": "MARKET_LOT_SIZE", "minQty": "0.00000000", "maxQty": "52400.00000000", "stepSize": "0.00000000"},
                                                           {"filterType": "MAX_NUM_ALGO_ORDERS", "maxNumAlgoOrders": 5}]}]
        }.to_json,
        headers: {
          "content-type" => "application/json;charset=utf-8",
        }
      )

    stub_request(:get, %r{https://api.binance.com/api/v3/account})
      .with(headers: authorized_headers)
      .to_return(status:  200,
                 body:    {
                   "makerCommission":  15,
                   "takerCommission":  15,
                   "buyerCommission":  0,
                   "sellerCommission": 0,
                   "canTrade":         true,
                   "canWithdraw":      true,
                   "canDeposit":       true,
                   "updateTime":       123_456_789,
                   "balances":         [
                     {
                       "asset":  "BTC",
                       "free":   "4723846.89208129",
                       "locked": "0.00000000"
                     },
                     {
                       "asset":  "LTC",
                       "free":   "4763368.68006011",
                       "locked": "100.00000000"
                     }
                   ],
                 }.to_json,
                 headers: {
                   "content-type" => "application/json;charset=utf-8",
                 })

    stub_request(:get, %r{https://api.binance.com/api/v3/openOrders})
      .with(headers: authorized_headers)
      .to_return(status:  200,
                 body:    [
                   {
                     "symbol":              "LTCBTC",
                     "orderId":             42,
                     "clientOrderId":       "myOrder1",
                     "price":               "0.1",
                     "origQty":             "1.0",
                     "executedQty":         "0.1",
                     "cummulativeQuoteQty": "0.0",
                     "status":              "NEW",
                     "timeInForce":         "GTC",
                     "type":                "LIMIT",
                     "side":                "BUY",
                     "stopPrice":           "0.0",
                     "icebergQty":          "0.0",
                     "time":                1_499_827_319_559,
                     "updateTime":          1_499_827_319_559,
                     "isWorking":           true
                   }
                 ].to_json,
                 headers: {
                   "content-type" => "application/json;charset=utf-8",
                 })
  end
end
