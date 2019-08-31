# frozen_string_literal: true

require 'webmock/rspec'
require 'rack'

shared_context 'mocked rubykube' do
  before(:each) do
    # TODO: find better way to store it (let is not accassible inside before)
    @authorized_api_key = '3107c98eb442e4135541d434410aaaa6'
    authorized_header = { 'X-Auth-Apikey'=> @authorized_api_key }

    # non-authorized requests

    stub_request(:post, /peatio\/market\/orders/).
    to_return(status: 403, body: '', headers: {})

    stub_request(:get, /peatio\/market\/orders/).
    to_return(status: 403, body: '', headers: {})

    stub_request(:get, /peatio\/account\/balances/).
    to_return(status: 403, body: '', headers: {})

    # authorized requests

    stub_request(:get, /peatio\/public\/timestamp/).
    with(headers: authorized_header).
    to_return(status: 200, body: '', headers: {})

    stub_request(:post, /peatio\/market\/orders/).
    with(headers: authorized_header).
    to_return(status: 201, body: { id: Random.rand(1...1000) }.to_json, headers: {})

    stub_request(:post, /peatio\/market\/orders\/\d+\/cancel/).
    with(headers: authorized_header).
    to_return(status: 201, body: '', headers: {})

    stub_request(:get, /peatio\/market\/orders/).
    with(headers: authorized_header).
    to_return(
      status: 200,
      body: [
        {'id'=>4, 'side'=>'sell', 'ord_type'=>'limit', 'price'=>'138.87', 'avg_price'=>'0.0', 'state'=>'wait', 'market'=>'fthusd', 'created_at'=>'2019-05-15T12:18:42+02:00', 'updated_at'=>'2019-05-15T12:18:42+02:00', 'origin_volume'=>'2.0', 'remaining_volume'=>'2.0', 'executed_volume'=>'0.0', 'trades_count'=>0},
        {'id'=>3, 'side'=>'buy', 'ord_type'=>'limit', 'price'=>'233.98', 'avg_price'=>'0.0', 'state'=>'wait', 'market'=>'fthusd', 'created_at'=>'2019-05-15T12:18:37+02:00', 'updated_at'=>'2019-05-15T12:18:37+02:00', 'origin_volume'=>'4.68', 'remaining_volume'=>'4.68', 'executed_volume'=>'0.0', 'trades_count'=>0},
        {'id'=>2, 'side'=>'sell', 'ord_type'=>'limit', 'price'=>'138.87', 'avg_price'=>'0.0', 'state'=>'wait', 'market'=>'fthusd', 'created_at'=>'2019-05-15T12:18:21+02:00', 'updated_at'=>'2019-05-15T12:18:21+02:00', 'origin_volume'=>'2.0', 'remaining_volume'=>'2.0', 'executed_volume'=>'0.0', 'trades_count'=>0},
        {'id'=>1, 'side'=>'buy', 'ord_type'=>'limit', 'price'=>'138.76', 'avg_price'=>'0.0', 'state'=>'wait', 'market'=>'fthusd', 'created_at'=>'2019-05-15T12:18:04+02:00', 'updated_at'=>'2019-05-15T12:18:04+02:00', 'origin_volume'=>'0.17', 'remaining_volume'=>'0.17', 'executed_volume'=>'0.0', 'trades_count'=>0}].to_json,
      headers: {Total: 4})

     stub_request(:get, /peatio\/account\/balances/).
    with(headers: authorized_header).
    to_return(
      status: 200,
      body: [
        {"currency"=>"eth", "balance"=>"0.0", "locked"=>"0.0"},
        {"currency"=>"fth", "balance"=>"1000000.0", "locked"=>"0.0"},
        {"currency"=>"trst", "balance"=>"0.0", "locked"=>"0.0"},
        {"currency"=>"usd", "balance"=>"999990.0", "locked"=>"10.0"}].to_json,
      headers: {})
  end
end

shared_context 'mocked binance' do
  before(:each) do
    @authorized_api_key = 'Uwg8wqlxueiLCsbTXjlogviL8hdd60'
    authorized_headers = { 'X-MBX-APIKEY' => @authorized_api_key }

    stub_request(:post, 'https://api.binance.com/api/v3/order').
    to_return(status: 401, body: 'Unauthorized', headers: {})

    stub_request(:get, "https://api.binance.com/api/v1/depth?limit=1000&symbol=ETHUSDT").
    to_return(
      status: 200,
      body: {
        "lastUpdateId"=>320927259,
        "bids"=>[["135.87000000", "36.43875000", []], ["135.85000000", "0.57176000", []], ["135.84000000", "6.62227000", []]],
        "asks"=>[["135.91000000", "0.00070000", []], ["135.93000000", "8.00000000", []], ["135.95000000", "1.11699000", []]]
      }.to_json,
      headers: {
        "content-type" => "application/json;charset=utf-8",
      })

    stub_request(:post, /https:\/\/api.binance.com\/api\/v3\/order/).
    with(headers: authorized_headers).
    to_return(status: 200, body: '', headers: {})


    stub_request(:get, "https://api.binance.com/api/v1/exchangeInfo").
    to_return(
      status: 200,
      body: {
        "timezone": "UTC",
        "serverTime": 1560347502144,
        "rateLimits":
          [{"rateLimitType": "REQUEST_WEIGHT", "interval": "MINUTE", "intervalNum": 1, "limit": 1200},
          {"rateLimitType": "ORDERS", "interval": "SECOND", "intervalNum": 1, "limit": 10},
          {"rateLimitType": "ORDERS", "interval": "DAY", "intervalNum": 1, "limit": 100000}],
        "exchangeFilters": [],
        "symbols":
          [{"symbol": "ETHUSDT",
          "status": "TRADING",
          "baseAsset": "ETH",
          "baseAssetPrecision"=>8,
          "quoteAsset": "USDT",
          "quotePrecision": 8,
          "orderTypes": ["LIMIT", "LIMIT_MAKER", "MARKET", "STOP_LOSS_LIMIT", "TAKE_PROFIT_LIMIT"],
          "icebergAllowed": true,
          "isSpotTradingAllowed": true,
          "isMarginTradingAllowed": true,
          "filters":
            [{"filterType": "PRICE_FILTER", "minPrice": "0.01000000", "maxPrice": "10000000.00000000", "tickSize": "0.01000000"},
            {"filterType": "PERCENT_PRICE", "multiplierUp": "5", "multiplierDown": "0.2", "avgPriceMins": 5},
            {"filterType": "LOT_SIZE", "minQty": "0.00001000", "maxQty": "10000000.00000000", "stepSize": "0.00001000"},
            {"filterType": "MIN_NOTIONAL", "minNotional": "10.00000000", "applyToMarket": true, "avgPriceMins": 5},
            {"filterType": "ICEBERG_PARTS", "limit": 10},
            {"filterType": "MARKET_LOT_SIZE", "minQty": "0.00000000", "maxQty": "52400.00000000", "stepSize": "0.00000000"},
            {"filterType": "MAX_NUM_ALGO_ORDERS", "maxNumAlgoOrders": 5}]}]}.to_json,
      headers: {
        "content-type" => "application/json;charset=utf-8",
      })

    stub_request(:get, /https:\/\/api.binance.com\/api\/v3\/account/).
    with(headers: authorized_headers).
    to_return(status: 200,
      body: {
        "makerCommission": 15,
        "takerCommission": 15,
        "buyerCommission": 0,
        "sellerCommission": 0,
        "canTrade": true,
        "canWithdraw": true,
        "canDeposit": true,
        "updateTime": 123456789,
        "balances": [
          {
            "asset": "BTC",
            "free": "4723846.89208129",
            "locked": "0.00000000"
          },
          {
            "asset": "LTC",
            "free": "4763368.68006011",
            "locked": "100.00000000"
          }
        ],
      }.to_json,
      headers: {
        "content-type" => "application/json;charset=utf-8",
      }
    )

    stub_request(:get, /https:\/\/api.binance.com\/api\/v3\/openOrders/).
    with(headers: authorized_headers).
    to_return(status: 200,
      body: [
        {
          "symbol": "LTCBTC",
          "orderId": 42,
          "clientOrderId": "myOrder1",
          "price": "0.1",
          "origQty": "1.0",
          "executedQty": "0.1",
          "cummulativeQuoteQty": "0.0",
          "status": "NEW",
          "timeInForce": "GTC",
          "type": "LIMIT",
          "side": "BUY",
          "stopPrice": "0.0",
          "icebergQty": "0.0",
          "time": 1499827319559,
          "updateTime": 1499827319559,
          "isWorking": true
        }
      ].to_json,
      headers: {
        "content-type" => "application/json;charset=utf-8",
      }
    )
  end
end


shared_context 'mocked huobi' do
  before(:each) do
    stub_request(:get, "https://api.huobi.pro/market/depth?symbol=ethusdt&type=step0").
    to_return(
      status: 200,
      body: {
        "tick": {
          "version": 31615842081,
          "ts": 1489464585407,
          "bids": [
            ["135.84000000", "6.62227000"],
            ["135.85000000", "0.57176000"],
            ["135.87000000", "36.43875000"],
          ],
          "asks": [
            ["135.91000000", "0.00070000"],
            ["135.93000000", "8.00000000"],
            ["135.95000000", "1.11699000"],
          ]
        }
        }.to_json,
      headers: {})

    stub_request(:get, build_url('/v1/account/accounts', 'GET')).
    to_return(status: 200, body: {
      "data": [
        {
          "id": 123,
          "type": "spot",
          "state": "working",
          "user-id": 1000
        },
      ]
      }.to_json, headers: {
        "content-type" => "application/json;charset=utf-8"
      })

    stub_request(:get, build_url('/v1/account/accounts/123/balance', 'GET')).
    to_return(status: 200,
      body: {
        "data": {
          "id": 123,
          "type": "spot",
          "state": "working",
          "list": [
            {
              "currency": "usdt",
              "type": "trade",
              "balance": "123.0"
            },
            {
              "currency": "usdt",
              "type": "frozen",
              "balance": "32.0"
            },
           {
              "currency": "eth",
              "type": "trade",
              "balance": "499999894616.1302471000"
            }
          ],
        }
      }.to_json,
      headers: {
        "content-type" => "application/json;charset=utf-8"
      })

    stub_request(:post, build_url('/v1/order/orders/place', 'POST')).
    to_return(status: 200,
      body: {
        "data": "59378"
      }.to_json,
      headers: {
        "content-type" => "application/json;charset=utf-8"
      })

    stub_request(:get, build_url('/v1/order/openOrders', 'GET')).
    to_return(status: 200,
      body: {
        "data": [
          {
            "id": 42,
            "symbol": "ethusdt",
            "account-id": 123,
            "amount": "1.000000000000000000",
            "price": "0.453000000000000000",
            "created-at": 1530604762277,
            "type": "sell-limit",
            "filled-amount": "0.0",
            "filled-cash-amount": "0.0",
            "filled-fees": "0.0",
            "source": "web",
            "state": "submitted"
          },
          {
            "id": 43,
            "symbol": "ethusdt",
            "account-id": 123,
            "amount": "0.500000000000000000",
            "price": "0.452000000000000000",
            "created-at": 1530604762277,
            "type": "buy-limit",
            "filled-amount": "0.2",
            "filled-cash-amount": "0.0",
            "filled-fees": "0.0",
            "source": "web",
            "state": "submitted"
          }
        ]
      }.to_json,
      headers: {
        "content-type" => "application/json;charset=utf-8"
      })
  end

  def build_url(path, method)
    api_key = 'Uwg8wqlxueiLCsbTXjlogviL8hdd60'
    secret = 'OwpadzSYOSkzweoJkjPrFeVgjOwOuxVHk8FXIlffdWw'

    h = {
      AccessKeyId: api_key,
      SignatureMethod: "HmacSHA256",
      SignatureVersion: 2,
      Timestamp: Time.now.getutc.strftime("%Y-%m-%dT%H:%M:%S")
    }
    data = "#{method}\napi.huobi.pro\n#{path}\n#{Rack::Utils.build_query(hash_sort(h))}"
    h["Signature"] = Base64.encode64(OpenSSL::HMAC.digest('sha256',secret,data)).gsub("\n","")
    url = "https://api.huobi.pro#{path}?#{Rack::Utils.build_query(h)}"
  end

  def hash_sort(ha)
    Hash[ha.sort_by{|key, val|key}]
  end
end

shared_context 'mocked luno' do
  before(:each) do
    authorized_headers = {
      "Authorization" => "Basic YWJjZGVmZ2hpamtsbTpza2hma3NqaGdrc2RqaGZrc2pkZmtqc2Rma3NqaGRrZnNq",
    }

    stub_request(:get, "https://api.mybitx.com/api/1/balance").
    with(headers: authorized_headers).
    to_return(status: 200,
      body: {"balance"=>
      [{"account_id"=>"321654654654321654",
        "asset"=>"XBT",
        "balance"=>"90.00",
        "reserved"=>"10.00",
        "unconfirmed"=>"0.00"}]}.to_json,
      headers: {"content-type" => "application/json"})

      stub_request(:get, "https://api.mybitx.com/api/1/orderbook?pair=XBTZAR").
      with(headers: authorized_headers).
      to_return(status: 200,
        body: {
          "timestamp": 1366305398592,
          "bids": [
            {
              "volume": "0.10",
              "price": "1100.00"
            },
            {
              "volume": "0.10",
              "price": "1000.00"
            },
            {
              "volume": "0.10",
              "price": "900.00"
            }
          ],
          "asks": [
            {
              "volume": "0.10",
              "price": "1180.00"
            },
            {
              "volume": "0.10",
              "price": "2000.00"
            }
          ]
        }.to_json,
        headers: {"content-type" => "application/json"})

        stub_request(:get, "https://api.mybitx.com/api/1/tickers").
        with(headers: authorized_headers).
        to_return(status: 200,
          body: {"tickers":[{"pair":"XBTNGN","timestamp":1560438897556,"bid":"2919998.00","ask":"2919999.00","last_trade":"2919999.00","rolling_24_hour_volume":"54.655802"},{"pair":"XBTZAR","timestamp":1560438897560,"bid":"127099.00","ask":"127100.00","last_trade":"127100.00","rolling_24_hour_volume":"519.677128"},{"pair":"XBTZMW","timestamp":1560438897563,"bid":"112433.00","ask":"112905.00","last_trade":"113622.00","rolling_24_hour_volume":"0.000792"},{"pair":"ETHXBT","timestamp":1560438897566,"bid":"0.0317","ask":"0.0318","last_trade":"0.0318","rolling_24_hour_volume":"1204.24"},{"pair":"XBTEUR","timestamp":1560438897569,"bid":"7276.55","ask":"7279.78","last_trade":"7244.49","rolling_24_hour_volume":"4.4105"},{"pair":"XBTIDR","timestamp":1560438897572,"bid":"116500000.00","ask":"116677000.00","last_trade":"116678000.00","rolling_24_hour_volume":"3.22731"},{"pair":"XBTMYR","timestamp":1560438897580,"bid":"8886.00","ask":"8938.00","last_trade":"8938.00","rolling_24_hour_volume":"0.59157"}]}.to_json,
          headers: {"content-type" => "application/json"})

        stub_request(:post, "https://api.mybitx.com/api/1/postorder").
        with(headers: authorized_headers).
        to_return(status: 200,
          body: { "order_id": "123456789"}.to_json,
          headers: {"content-type" => "application/json"})
  end
end

shared_context 'mocked bitfinex' do
  before(:each) do
    @authorized_api_key = 'Uwg8wqlxueiLCsbTXjlogviL8hdd60'
    authorized_headers = { 'x-bfx-apikey' => @authorized_api_key }

    stub_request(:post, 'https://api.bitfinex.com/v1/balances').
    to_return(status: 401, body: {"message"=>"Could not find a key matching the given X-BFX-APIKEY."}.to_json, headers: {"content-type" => "application/json;charset=utf-8"})

    stub_request(:post, 'https://api.bitfinex.com/v1/order/new').
    with(headers: authorized_headers).
    to_return(status: 200,
      body: {
        "id":448364249,
        "symbol":"ethusd",
        "exchange":"bitfinex",
        "price":"135.84",
        "avg_execution_price":"0.0",
        "side":"buy",
        "type":"exchange limit",
        "timestamp":"1444272165.252370982",
        "is_live":true,
        "is_cancelled":false,
        "is_hidden":false,
        "was_forced":false,
        "original_amount":"6.62227",
        "remaining_amount":"6.62227",
        "executed_amount":"0.0",
        "order_id":448364249
      }.to_json, headers: {"content-type" => "application/json;charset=utf-8"})

    stub_request(:post, 'https://api.bitfinex.com/v1/orders').
    with(headers: authorized_headers).
    to_return(status: 200,
      body:
        [{
          "id":123,
          "symbol":"ethusd",
          "exchange":"bitfinex",
          "price":"0.02",
          "avg_execution_price":"0.0",
          "side":"buy",
          "type":"exchange limit",
          "timestamp":"1444276597.0",
          "is_live":true,
          "is_cancelled":false,
          "is_hidden":false,
          "was_forced":false,
          "original_amount":"0.3",
          "remaining_amount":"0.2",
          "executed_amount":"0.1"
        },
        {
          "id":124,
          "symbol":"ethusd",
          "exchange":"bitfinex",
          "price":"0.02",
          "avg_execution_price":"0.0",
          "side":"buy",
          "type":"exchange limit",
          "timestamp":"1444276597.0",
          "is_live":false,
          "is_cancelled":false,
          "is_hidden":false,
          "was_forced":false,
          "original_amount":"0.3",
          "remaining_amount":"0.2",
          "executed_amount":"0.1"
        },
        {
          "id":125,
          "symbol":"btcusd",
          "exchange":"bitfinex",
          "price":"0.02",
          "avg_execution_price":"0.0",
          "side":"buy",
          "type":"exchange limit",
          "timestamp":"1444276597.0",
          "is_live":true,
          "is_cancelled":false,
          "is_hidden":false,
          "was_forced":false,
          "original_amount":"0.3",
          "remaining_amount":"0.2",
          "executed_amount":"0.1"
        }].to_json, headers: {
        "content-type" => "application/json;charset=utf-8"
        })

    stub_request(:post, 'https://api.bitfinex.com/v1/balances').
    with(headers: authorized_headers).
    to_return(status: 200,
      body: [
        {
          "type":"deposit",
          "currency":"eth",
          "amount":"100.12",
          "available":"100.12"
        },{
          "type":"deposit",
          "currency":"usd",
          "amount":"110",
          "available":"100"
        }
      ].to_json, headers: {"content-type" => "application/json;charset=utf-8"})
  end
end

shared_context 'mocked hitbtc' do
  before(:each) do
    authorized_headers = {
      "Authorization" => "Basic YWJjZGVmZ2hpamtsbTpza2hma3NqaGdrc2RqaGZrc2pkZmtqc2Rma3NqaGRrZnNq",
    }

    stub_request(:get, "https://api.hitbtc.com/api/2/trading/balance").
    with(headers: authorized_headers).
    to_return(status: 200,
      body: [
        {
          "currency": "ETH",
          "available": "10.000000000",
          "reserved": "0.560000000"
        },
        {
          "currency": "USD",
          "available": "0.010205869",
          "reserved": "0"
        }
      ].to_json,
      headers: {"content-type" => "application/json"})

      stub_request(:get, "https://api.hitbtc.com/api/2/public/orderbook/ETHUSD").
      with(headers: authorized_headers).
      to_return(status: 200,
        body: {
          "ask": [
            {
              "price": "0.046002",
              "size": "0.088"
            },
            {
              "price": "0.046800",
              "size": "0.200"
            }
          ],
          "bid": [
            {
              "price": "0.046001",
              "size": "0.005"
            },
            {
              "price": "0.046000",
              "size": "0.200"
            }
          ],
          "timestamp": "2018-11-19T05:00:28.193Z"
        }.to_json,
        headers: {"content-type" => "application/json"})

        stub_request(:get, "https://api.hitbtc.com/api/2/public/symbol").
        with(headers: authorized_headers).
        to_return(status: 200,
          body: [
            {
              "id": "ETHBTC",
              "baseCurrency": "ETH",
              "quoteCurrency": "BTC",
              "quantityIncrement": "0.001",
              "tickSize": "0.000001",
              "takeLiquidityRate": "0.001",
              "provideLiquidityRate": "-0.0001",
              "feeCurrency": "BTC"
            },
            {
              "id": "ETHUSD",
              "baseCurrency": "ETH",
              "quoteCurrency": "USD",
              "quantityIncrement": "0.001",
              "tickSize": "0.000001",
              "takeLiquidityRate": "0.001",
              "provideLiquidityRate": "-0.0001",
              "feeCurrency": "USD"
            },
          ].to_json,
          headers: {"content-type" => "application/json"})

        stub_request(:post, "https://api.hitbtc.com/api/2/order").
        with(headers: authorized_headers).
        to_return(status: 200,
          body: {
              "id": 0,
              "clientOrderId": "d8574207d9e3b16a4a5511753eeef175",
              "symbol": "ETHBTC",
              "side": "sell",
              "status": "new",
              "type": "limit",
              "timeInForce": "GTC",
              "quantity": "0.063",
              "price": "0.046016",
              "cumQuantity": "0.000",
              "postOnly": false,
              "createdAt": "2017-05-15T17:01:05.092Z",
              "updatedAt": "2017-05-15T17:01:05.092Z"
          }.to_json,
          headers: {"content-type" => "application/json"})
  end
end
