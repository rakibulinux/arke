# Arke Server

## Start a bot

```json
[1,42,"start_bot",{"bot_id":1,"log_level":"INFO","accounts":[{"id":"bitfaker","driver":"bitfaker","delay":1,"balances":{"btc":3,"usd":10000}}],"strategies":[{"id":"candle-FTHUSD","type":"candle_sampling","debug":true,"enabled":true,"period":1000,"params":{"sampling_ratio":100000,"max_slippage":0.005},"sources":[{"account_id":"bitfaker","market_id":"ETHUSDT"}],"target":{"account_id":"bitfaker","market_id":"ethusdt"}}]}]
```
