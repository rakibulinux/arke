# Arke

### Quick-Start

Configure your trading strategies the file *config/strategies.yml*

Run Arke with this command

```bash
./bin/arke start
```


### Example of Arke configuration

```yaml
log_level: INFO
accounts:
- id: 1
  driver: rubykube
  debug: false
  host: "https://example.com"
  ws: "wss://example.com"
  key: ""
  secret: ""
  delay: 0.75

- id: 2
  driver: rubykube
  debug: false
  host: "https://example.com"
  ws: "wss://example.com"
  key: ""
  secret: ""
  delay: 0.01

- id: 3
  driver: binance
  host: "api.binance.com"
  key: ""
  secret: ""
  delay: 1

strategies:
- id: BTCUSDT-orderback
  type: orderback
  debug: false
  enabled: true
  period: 90
  params:
    spread_bids: 0.005
    spread_asks: 0.005
    limit_asks_base: 10
    limit_bids_base: 10
    levels_size: 0.5
    levels_count: 5
    side: both
    enable_orderback: false

  target:
    account_id: 1
    market:
      id: BTCUSDT
      base: btc
      quote: usdt
      base_precision: 4
      quote_precision: 4
      min_ask_amount: 0.015
      min_bid_amount: 0.015

  sources:
  - account_id: 3
    market:
      id: BTCUSDT
      base: BTC
      quote: USDT
      base_precision: 8
      quote_precision: 8
      min_order_back_amount: 0.0002

- id: BTCUSDT-micro
  type: microtrades
  debug: false
  period: 30
  period_random_delay: 30
  enabled: false
  params:
    linked_strategy_id: BTCUSDT-orderback
    min_amount: 0.0001
    max_amount: 0.01
    min_price: 170
    max_price: 230

  target:
    account_id: 2
    market:
      id: BTCUSDT
      base: btc
      quote: usdt
      base_precision: 4
      quote_precision: 4

```

#### Account config

| Field    | Description                                                  |
| -------- | ------------------------------------------------------------ |
| `id`     | ID identifying the account (have to be unique)               |
| `driver` | Name of exchange driver (supported values are: `rubykube`, `binance`, `bitfinex`) |
| `debug`  | Flag to extend logs verbosity, valid values are: `true` or `false` |
| `host`   | Base URL of the exchange API                                 |
| `ws`     | Websocket URL of exchange                                    |
| `key`    | API key                                                      |
| `secret` | Secret key                                                   |
| `delay`  | Minimum delay to respect between requests to this exchange (in second) |



### Strategies configuration

#### General configuration

| Field                 | Description                                                  |
| --------------------- | ------------------------------------------------------------ |
| `id`                  | ID of the strategy (arbitrary string, must be unique)        |
| `type`                | Strategy type (valid:  `orderback`, `fixedprice`, `microtrades`, `copy`) |
| `debug`               | Flag to extend logs verbosity, valid values are: `true` or `false` |
| `enabled`             | Flag to enable the strategy, could be: `true` or `false`     |
| `period`              | Orderbook update period (in seconds), remember about delay in accounts and rate limit in peatio |
| `period_random_delay` | Random delay which will be added to the static period        |



#### Parameters for strategies

##### Copy strategy

The *Copy* strategy uses a source exchange market to create an orderbook on a target market. The depth of the created orderbook is defined by the number of orders in each side with the *levels_count* parameter and the price difference between orders with the *price_size* parameter.

Orders amount are set according to the source orders volume of the same price level.

| Field             | Description                                                  |
| ----------------- | ------------------------------------------------------------ |
| `spread_bids`     | Spread for bids side (in percentage)                         |
| `spread_asks`     | Spread for asks side (in percentage)                         |
| `limit_asks_base` | Sum of amounts of orders of ask side                         |
| `limit_bids_base` | Sum of amounts of orders of bid side                         |
| `levels_size`     | Minimum price difference between orders                      |
| `levels_count`    | Number of orders for each side                               |
| `side`            | Side where orders will be created (valid: `asks`, `bids`, `both`) |



##### Orderback strategy

This strategy behaves like the *Copy* strategy and have the ability to order back the liquidity from the source exchange market.
An soon as an order is matched, the strategy creates an order on the source exchange with the matched amount and the same price without the spread. This way if the spread configured is higher than the exchanges fee the P&L will be positive.
Notice that the amount of the trade must be higher than the *min_order_back_amount* parameter set on the source exchange for the order back to be created, otherwise the trade will be ignored.

| Field              | Description                                                  |
| ------------------ | ------------------------------------------------------------ |
| `spread_bids`      | Spread for bids side (in percentage)                         |
| `spread_asks`      | Spread for asks side (in percentage)                         |
| `limit_asks_base`  | Sum of amounts of orders of ask side                         |
| `limit_bids_base`  | Sum of amounts of orders of bid side                         |
| `levels_size`      | Minimum price difference between orders                      |
| `levels_count`     | Number of orders for each side                               |
| `side`             | Side where orders will be created (valid: `asks`, `bids`, `both`) |
| `enable_orderback` | Flag for enabling orderback, could be: `true` or `false`     |



##### Fixedprice strategy

This strategy creates an orderbook on a market without using any source market.
It creates an order arround the reference *price* with a random value *random_delta* added or substracted to this price.

| Field             | Description                                                  |
| ----------------- | ------------------------------------------------------------ |
| `spread_bids`     | Spread for bids side (in percentage)                         |
| `spread_asks`     | Spread for asks side (in percentage)                         |
| `limit_asks_base` | Sum of amounts of orders of ask side                         |
| `limit_bids_base` | Sum of amounts of orders of bid side                         |
| `levels_size`     | Minimum price difference between orders                      |
| `levels_count`    | Number of orders for each side                               |
| `side`            | Side where orders will be created (valid: `asks`, `bids`, `both`) |
| `price`           | Reference price for the strategy to create orderbook         |
| `random_delta`    | Random value for deviation of the reference price (maximum deviation = random_delta / 2) |



##### Microtrades strategy

This strategy creates random trades on a market with random amounts.
It is commonly used to create candles on a market with low activity.

| Field                | Description                                                  |
| -------------------- | ------------------------------------------------------------ |
| `linked_strategy_id` | OPTIONAL. ID of strategy which will be referred (using for calculating price) |
| `price_difference`   | OPTIONAL. Change of calculated price (using if `linked_strategy_id` exist) |
| `min_amount`         | Minimum amount of order                                      |
| `max_amount`         | Maximum amount of order                                      |
| `min_price`          | OPTIONAL. Price for ask orders (using if `linked_strategy_id` doesn't exist) |
| `max_price`          | OPTIONAL. Price for bid orders (using if `linked_strategy_id` doesn't exist) |



#### Market configuration

| Field                  | Description                                                  |
| ---------------------- | ------------------------------------------------------------ |
| `id`                   | ID of market                                                 |
| `base`                 | Base currency of market                                      |
| `quote`                | Quote currency of market                                     |
| `base_precision`       | Base precision of market                                     |
| `quote_precision`      | Quote precision of market                                    |
| `min_orderback_amount` | OPTIONAL. This parameter is used by strategies which support order back, see strategies documentation for more details. |



##### Target configuration

| Field        | Description                                             |
| ------------ | ------------------------------------------------------- |
| `account_id` | ID of account which will place order on target exchange |
| `market`     | Market configuration you can see above                  |



##### Sources configuration

| Field        | Description                                             |
| ------------ | ------------------------------------------------------- |
| `account_id` | ID of account which will place order on target exchange |
| `market`     | Market configuration you can see above                  |