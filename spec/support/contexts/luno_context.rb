# frozen_string_literal: true

shared_context "mocked luno" do
  before(:each) do
    authorized_headers = {
      "Authorization" => "Basic YWJjZGVmZ2hpamtsbTpza2hma3NqaGdrc2RqaGZrc2pkZmtqc2Rma3NqaGRrZnNq",
    }

    stub_request(:get, "https://api.mybitx.com/api/1/balance")
      .with(headers: authorized_headers)
      .to_return(status:  200,
                 body:    {"balance" =>
                                        [{"account_id"  => "321654654654321654",
                                          "asset"       => "XBT",
                                          "balance"     => "90.00",
                                          "reserved"    => "10.00",
                                          "unconfirmed" => "0.00"}]}.to_json,
                 headers: {"content-type" => "application/json"})

    stub_request(:get, "https://api.mybitx.com/api/1/orderbook?pair=XBTZAR")
      .with(headers: authorized_headers)
      .to_return(status:  200,
                 body:    {
                   "timestamp": 1_366_305_398_592,
                   "bids":      [
                     {
                       "volume": "0.10",
                       "price":  "1100.00"
                     },
                     {
                       "volume": "0.10",
                       "price":  "1000.00"
                     },
                     {
                       "volume": "0.10",
                       "price":  "900.00"
                     }
                   ],
                   "asks":      [
                     {
                       "volume": "0.10",
                       "price":  "1180.00"
                     },
                     {
                       "volume": "0.10",
                       "price":  "2000.00"
                     }
                   ]
                 }.to_json,
                 headers: {"content-type" => "application/json"})

    stub_request(:get, "https://api.mybitx.com/api/1/tickers")
      .with(headers: authorized_headers)
      .to_return(status:  200,
                 body:    {"tickers": [{"pair": "XBTNGN", "timestamp": 1_560_438_897_556, "bid": "2919998.00", "ask": "2919999.00", "last_trade": "2919999.00", "rolling_24_hour_volume": "54.655802"}, {"pair": "XBTZAR", "timestamp": 1_560_438_897_560, "bid": "127099.00", "ask": "127100.00", "last_trade": "127100.00", "rolling_24_hour_volume": "519.677128"}, {"pair": "XBTZMW", "timestamp": 1_560_438_897_563, "bid": "112433.00", "ask": "112905.00", "last_trade": "113622.00", "rolling_24_hour_volume": "0.000792"}, {"pair": "ETHXBT", "timestamp": 1_560_438_897_566, "bid": "0.0317", "ask": "0.0318", "last_trade": "0.0318", "rolling_24_hour_volume": "1204.24"}, {"pair": "XBTEUR", "timestamp": 1_560_438_897_569, "bid": "7276.55", "ask": "7279.78", "last_trade": "7244.49", "rolling_24_hour_volume": "4.4105"}, {"pair": "XBTIDR", "timestamp": 1_560_438_897_572, "bid": "116500000.00", "ask": "116677000.00", "last_trade": "116678000.00", "rolling_24_hour_volume": "3.22731"}, {"pair": "XBTMYR", "timestamp": 1_560_438_897_580, "bid": "8886.00", "ask": "8938.00", "last_trade": "8938.00", "rolling_24_hour_volume": "0.59157"}]}.to_json,
                 headers: {"content-type" => "application/json"})

    stub_request(:post, "https://api.mybitx.com/api/1/postorder")
      .with(headers: authorized_headers)
      .to_return(status:  200,
                 body:    {"order_id": "123456789"}.to_json,
                 headers: {"content-type" => "application/json"})
  end
end
