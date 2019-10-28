# How to debug arke configs

## Simplify your config

First step is disable all strategies except the one you want to debug
use *enabled: false* in yaml or comment the section with '#'

##  Compare market precision

Most crypto-currency are quoted in USD which has a `quote_precision = 2`
But every exchange practice different precision

Reminder, on the market BTCUSD, BTC is base currency, USD is quote currency
Amounts will be in BTC, price in USD

For Binance use:
```
curl https://www.binance.com/api/v1/exchangeInfo | jq
```

For OpenDAX use:
```
curl https://stage.emirex.com/api/v2/peatio/public/markets | jq
```

correct the following values:
```
base_precision: 5   # Precision for base currency
quote_precision: 2  # Precision for quote currency
```

## Copy the config on your computer

We advise you to copy the configuration on your linux desktop
and debug using your computer.

You can run arke container and mount config in `config/strategies.yml`

## Inspect logs

On first run follow the error in logs
You may have permissions denied, precision config issues

Also the exchange may not accept your order if amount is too small



## Understand the *copy* or *orderback* target orderbook

Every parameter of the *copy* and *orderback* strategies will impact the output orderbook.

Those strategies build the orderbook with the following steps:

- Fetch source orderbook
- Creates price points for the target orderbook considering the *levels_size*, *levels_count* and the best prices from the source orderbook
- Create levels by aggregating the source orderbook around the price points
  It sums orders amounts and compute weighted prices for every range
- Adjust volume of every level to match users expectations (*limit_asks_base* and *limit_bids_base*)
- Finally it applies the configured spread to every level

To understand how the strategy build the orderbook you should first enable the debug mode on the strategy itself (*debug: true*).

You will see from the logs the following outputs:

- step "2_ob" shows the source orderbook aggregated according to your levels:
  (The price is on the left, the level volume on right)

  ```D, [2019-10-28T14:34:03.282304 #13710] DEBUG -- : 2_ob:
  D, [2019-10-28T14:34:03.282304 #13710] DEBUG -- : 2_ob:
  asks
    182.97571942       479.09274000000005
    183.20013710       359.41229999999996
    183.46955547       339.52265000000006
    183.77569465       317.8778
    183.92952722       19.818489999999994
  bids
    182.60651941       518.40322
    182.44573305       433.26763999999986
    182.17163169       349.86021999999997
    181.94000310       335.43544
    181.64365371       462.15312
  ```

- step "3_ob_adjusted" shows the orderbook after volumes adjusted to user expectations

```
D, [2019-10-28T14:34:03.282366 #13710] DEBUG -- : 3_ob_adjusted:
asks
  182.97571942       3.1608178423092577
  183.20013710       2.3712252675450842
  183.46955547       2.2400031567752863
  183.77569465       2.0972011012189697
  183.92952722       0.13075263215140262
bids
  182.60651941       2.469622074518821
  182.44573305       2.064044524875199
  182.17163169       1.666699759905062
  181.94000310       1.5979815233399466
  181.64365371       2.2016521173609718
```



- step "4_ob_spread" shows the final targeted orderbook with spread applied

```
D, [2019-10-28T14:34:03.282432 #13710] DEBUG -- : 4_ob_spread:
asks
  183.52464658       3.1608178423092577
  183.74973751       2.3712252675450842
  184.01996414       2.2400031567752863
  184.32702174       2.0972011012189697
  184.48131580       0.13075263215140262
bids
  182.05869986       2.469622074518821
  181.89839585       2.064044524875199
  181.62511680       1.666699759905062
  181.39418309       1.5979815233399466
  181.09872275       2.2016521173609718
```

Notice that if the final volume of the level is lower than *min_bid_amount* or *min_ask_amount* the order amount will be truncated to the corresponding value.
