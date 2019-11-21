# How to deploy arke-proxy with opendax

## Edit config for arke ETL

First step is edit template for arke etl config

Config example template (/templates/config/arke/etl.yml.erb):

```yaml
log_level: INFO

shared_params:
  markets: [BTCUSDT, ETHUSDT, LTCUSDT, ETHBTC, LTCBTC, BATETH, LINKETH, OMGETH, LTCETH]

jobs:

  # Store tickers and forward to arke AMQP
  - extract: Tickers
    process:
      - load:
          AMQP:
            exchange: arke.events.ranger

  # Forward klines to arke AMQP
  - extract: Kline
    process:
      - load:
          AMQP:
            exchange: arke.events.ranger

  # Store non sampled binance trades and forward to arke AMQP
  - extract:
      Bitfinex:
        listen:
          - public_trades
    process:
      - load:
          Influx:
            measurment: trades
      - load:
          AMQP:
            exchange: arke.events.ranger

  # Store sampled binance trades and forward to arke AMQP
  - extract:
      Binance:
        listen:
          - public_trades
    transform:
     - Sample:
         ratio: 0.2  
    process:
      - load:
          Influx:
            measurment: trades
      - load:
          AMQP:
            exchange: arke.events.ranger

  # Listen peatio trades, store in Influx and forward to arke AMQP
  - extract:
      PeatioAMQP:
        exchange: peatio.events.ranger
        events:
          - {type: public, event: trades}
    process:
      - load:
          Influx:
            measurment: trades


  # Forward peatio events except tickers and klines
  - extract:
      AMQP:
        exchange: peatio.events.ranger
        events:
          - {type: public, event: update}
          - {type: public, event: trades}
          - {type: private}
    process:
      - load: Print
      - load:
          AMQP:
            exchange: arke.events.ranger
```

After edit etl config don't forget to execute:
```
rake render:config
```

## Start influxdb and load `CONTINUOUS QUERIES`

For advanced user:
```
docker-compose up -d influxdb
```

and

```
docker-compose exec influxdb bash -c "cat influxdb.sql | influx"
```

or you can run rake task:
```
rake service:influxdb
```

## Start Arke-proxy

For start arke-proxy you can execute following commands:
1. For start arke-proxy API
```
docker-compose up -Vd arke
```
2. For start arke-etl service
```
docker-compose up -Vd arke-etl
```

or you can run rake task:
```
rake service:arke_proxy
```