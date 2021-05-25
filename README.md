# Arke

### Quick-Start

Configure your trading strategies the file *config/strategies.yml*

Install dependencies
```bash
bundle install
```

Run Arke with this command

```bash
bundle exec ./bin/arke start
```


### Example of Arke configuration

```yaml
log_level: INFO
accounts:
- id: example-account1
  driver: rubykube
  debug: false
  host: "https://example.com"
  ws: "wss://example.com"
  key: ""
  secret: ""
  delay: 0.75

- id: example-account2
  driver: rubykube
  debug: false
  host: "https://example.com"
  ws: "wss://example.com"
  key: ""
  secret: ""
  delay: 1

- id: binance-account
  driver: binance
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
    min_order_back_amount: 0.0002

  target:
    account_id: example-account1
    market_id: BTCUSDT

  sources:
  - account_id: binance-account
    market_id: BTCUSDT

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
    account_id: example-account2
    market_id: BTCUSDT

```

#### Account config

| Field    | Description                                                  |
| -------- | ------------------------------------------------------------ |
| `id`     | ID identifying the account (must be unique)                  |
| `driver` | Name of exchange driver (supported values are: `opendax`, `finex`, `binance`, `bitfinex`, `kraken`) |
| `debug`  | Flag to extend logs verbosity, valid values are: `true` or `false` |
| `host`   | Base URL of the exchange API                                 |
| `ws`     | Websocket URL of exchange                                    |
| `key`    | API key                                                      |
| `secret` | Secret key                                                   |
| `delay`  | Minimum delay to respect between requests to this exchange (in second) |
| `disable_balance_check` | Indicates to strategies to not limit the orders creation by the account balance |

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
| `fx`                  | Forex conversion rate configuration to apply to price, read bellow the documentation of the section |



#### Parameters for strategies

##### Simple Copy strategy

The *simple-copy* strategy uses the mid-price (the middle price between the best ask and best bid of the orderbook) of a source orderbook and generate an orderbook using a predefined or custom pattern. The depth of the created orderbook is defined by the number of orders in each side with the *levels_count* parameter and the price difference between orders with the *levels_price_size* parameter.

Orders amount are set according to the source orders volume of the same price level.

| Field                  | Description                                                  |
| ---------------------- | ------------------------------------------------------------ |
| `spread_bids`          | Spread for bids side (in percentage)                         |
| `spread_asks`          | Spread for asks side (in percentage)                         |
| `balance_base_perc`    | Percentage of the balance to use in Asks side                |
| `balance_quote_perc`   | Percentage of the balance to use in Bids side                |
| `balance_perc`         | Percentage of the balance to use in both side if previous parameters are not specified |
| `levels_price_step`    | Minimum price difference between levels                      |
| `levels_price_func`    | Function to use for levels price step from the level, possibles values are `constant`, `linear`, `exp` |
| `levels_count`         | Number of orders for each side                               |
| `max_amount_per_order` | Maximum size for one order, if more liquidity is needed for one level several orders of this size will be created |
| `shape`                | Pattern to be used to generate the orderbook, possible values are `v`, `w` and `custom` |
| `random`               | Random factor to apply to every level, default is 0.3 for 30% |
| `levels`               | Levels pattern to use in case of `custom` shape. (ex: `[0.1, 0.2, 1, 2, 0.1]`) |

##### Copy strategy

The *copy* strategy uses a source exchange market to create an orderbook on a target market. The depth of the created orderbook is defined by the number of orders in each side with the *levels_count* parameter and the price difference between orders with the *price_size* parameter.

Orders amount are set according to the source orders volume of the same price level.

| Field                       | Description                                                                     |
| --------------------------- | ------------------------------------------------------------------------------- |
| `spread_bids`               | Spread for bids side (in percentage)                                            |
| `spread_asks`               | Spread for asks side (in percentage)                                            |
| `limit_asks_base`           | Sum of amounts of orders of ask side                                            |
| `limit_bids_base`           | Sum of amounts of orders of bid side                                            |
| `balance_base_perc`         | Ratio for sum of amounts of orders of ask side based on base currency balance   |
| `balance_quote_perc`        | Ratio for sum of amounts of orders of bid side based on quote currency balance  |
| `levels_price_step`         | Minimum price difference between levels                                         |
| `levels_price_func`         | Function to use to calculate levels size: `constant`, `linear`, `exp` (default: `constant`) |
| `levels_count`              | Number of orders for each side                                                  |
| `max_amount_per_order`      | Maximum size for one order, if more liquidity is needed for one level several orders of this size will be created |
| `side`                      | Side where orders will be created (valid: `asks`, `bids`, `both`)               |



##### Orderback strategy

This strategy behaves like the *Copy* strategy and have the ability to order back the liquidity from the source exchange market.
An soon as an order is matched, the strategy creates an order on the source exchange with the matched amount and the same price without the spread. This way if the spread configured is higher than the exchanges fee the P&L will be positive.

| Field                   | Description                                                  |
| ----------------------- | ------------------------------------------------------------ |
| `spread_bids`           | Spread for bids side (in percentage)                         |
| `spread_asks`           | Spread for asks side (in percentage)                         |
| `limit_asks_base`       | Sum of amounts of orders of ask side                         |
| `limit_bids_base`       | Sum of amounts of orders of bid side                         |
| `limit_by_source_balance` | Limit bids and asks amount according to the source account balances (default: `false`)|
| `balance_base_perc`     | Ratio for sum of amounts of orders of ask side based on base currency balance   |
| `balance_quote_perc`    | Ratio for sum of amounts of orders of bid side based on quote currency balance  |
| `levels_size`           | Minimum price difference between orders                      |
| `levels_count`          | Number of orders for each side                               |
| `levels_price_step`     | Minimum price difference between levels                                         |
| `levels_price_func`         | Function to use to calculate levels size: `constant`, `linear`, `exp` (default: `constant`) |
| `max_amount_per_order`  | Maximum size for one order, if more liquidity is needed for one level several orders of this size will be created |
| `side`                  | Side where orders will be created (valid: `asks`, `bids`, `both`) |
| `enable_orderback`      | Flag for enabling orderback, could be: `true` or `false`     |
| `min_order_back_amount` | The amount of the trade must be higher than this value for the order back to be created, otherwise the trade will be ignored. |
| `orderback_grace_time`  | The time to wait incoming trades before triggering the order back, default 1 sec |
| `orderback_type`  | The order back type it will be created, could be: `limit` or `market`, default is `market` |


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
| `max_amount_per_order` | Maximum size for one order, if more liquidity is needed for one level several orders of this size will be created |
| `price`           | Reference price for the strategy to create orderbook         |
| `random_delta`    | Random value for deviation of the reference price (maximum deviation = random_delta / 2) |

##### Candle-Sampling strategy

This strategy copies trades from sources every *sampling_ratio* trade events.
It will trigger a market order with the same amount than the average trades amount being copied in the window.
The parameter *max_slippage* protect against price slippage, it will considere the target orderbook and reduce the amount of the order accordingly to avoid price slippage.
A random of 10% is applied on the *sampling_ratio* to make the strategy not deterministic.
The *period* parameter doesn't affect this strategy since it only reacts on sources trade events.

| Field                | Description                                                  |
| -------------------- | ------------------------------------------------------------ |
| `sampling_ratio`     | Number of trades to wait before copying one, also used to divide the volume of trades |
| `max_slippage`       | Maximum price slippage allowed on a single trade triggered by the strategy |
| `max_balance`        | Maximum percentage of the balance allowed to be used for one trade |

##### Microtrades-Copy strategy

This strategy creates random trades on a market with random amounts following the price of one or several sources.
It is commonly used to create candles on a market with low activity.

| Field                | Description                                                  |
| -------------------- | ------------------------------------------------------------ |
| `min_amount`         | Minimum amount of order (defaults to market minimum order amount)|
| `max_amount`         | Maximum amount of order (defaults to 10 times the market minimum order amount) |
| `maker_taker_orders_delay`   | Time between maker and taker orders (defaults 0.02 sec) |
| `matching_timeout` | Time in seconds to wait before canceling microtrades orders (defaults 1 sec) |

##### Microtrades-Market strategy

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

##### Circuitbraker strategy

This strategy monitors orders on an account, compare prices with a source exchange and cancel those which are too far from current orderbook offers on the source.

It is a security in case the strategy which creates the market crash or have a defect.

| Field                | Description                                                  |
| -------------------- | ------------------------------------------------------------ |
| `spread_bids`        | Spread to apply on bids side (in percentage)                 |
| `spread_asks`        | Spread to apply on asks side (in percentage)                 |

The spread applied on circuitbraker strategy should be lower than the spead used by the strategy creating the orderbook.


##### Target configuration

| Field        | Description                                             |
| ------------ | ------------------------------------------------------- |
| `account_id` | ID of account which will place order on target exchange |
| `market_id`  | ID of the market as it is on the target exchange        |



##### Sources configuration

List of following configuration statement:

| Field        | Description                                             |
| ------------ | ------------------------------------------------------- |
| `account_id` | ID of account which will place order on target exchange |
| `market_id`  | ID of the market as it is on the source exchange        |

##### Static forex conversion rate configuration

Detail of the `fx` section to configure for a strategy:

| Field        | Value          | Description                                                 |
| ------------ | -------------- | ----------------------------------------------------------- |
| `type`       | "static"       | The type of the forex class to use, which is "static" here  |
| `rate`       | float          | Static value of the rate to apply to prices of the strategy |

##### Dynamic forex conversion rate configuration

Detail of the `fx` section to configure for a strategy:

| Field           | Value   | Description                                                                    |
| --------------- | ------- | ------------------------------------------------------------------------------ |
| `type`          | "fixer" | The type of the forex class to use, the supported value is "fixer" for dynamic |
| `api_key`       | string  | Fixer api key                                                                  |
| `currency_from` | string  | Currency code                                                                  |
| `currency_to`   | string  | Currency code                                                                  |
| `period`        | seconds | Refresh period in seconds, default: 3600                                       |
| `https`         | boolean | Enable https communication (default true)                                      |

