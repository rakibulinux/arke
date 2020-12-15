# Arke Server

## Start a bot

1. Quiet example with candle_sampling strategy

```json
[1,42,"start_bot",{"bot_id":1,"log_level":"INFO","accounts":[{"id":"bitfaker","driver":"bitfaker","delay":1,"balances":{"btc":3,"usd":10000}}],"strategies":[{"id":"candle-FTHUSD","type":"candle_sampling","debug":true,"enabled":true,"period":1000,"params":{"sampling_ratio":100000,"max_slippage":0.005},"sources":[{"account_id":"bitfaker","market_id":"ETHUSDT"}],"target":{"account_id":"bitfaker","market_id":"ethusdt"}}]}]
```


2. Example with active logs

```json
[1,42,"start_bot",{"bot_id":1,"log_level":"INFO","accounts":[{"id":"bitfaker","driver":"bitfaker","delay":1,"balances":{"btc":3,"usd":10000}}],"strategies":[{"id":"copy-ETHUSD","type":"copy","debug":true,"enabled":true,"period":30,"fx":{"type":"static","rate":1.8},"params":{"spread_bids":0.003,"spread_asks":0.003,"limit_asks_base":100,"limit_bids_base":100,"max_amount_per_order":0.5,"levels_size":1,"levels_count":10,"side":"both"},"target":{"account_id":"bitfaker","market_id":"BTCUSD"},"sources":[{"account_id":"bitfaker","market_id":"BTCUSD"}]},{"id":"microtrades-FTHUSD","type":"microtrades","debug":true,"enabled":false,"period":5,"period_random_delay":10,"params":{"min_amount":0.05,"max_amount":0.3},"target":{"account_id":"bitfaker","market_id":"BTCUSD"}}]}]
```

