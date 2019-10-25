# How to debug arke configs

## Simplify your config

First step is disable all strategies execpt the main one
use enabled: false in yaml or comment the section with '#'

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


Guide to be continued...
