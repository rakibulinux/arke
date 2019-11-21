# frozen_string_literal: true

require "clamp"
require "rbtree"
require "json"
require "openssl"
require "ostruct"
require "yaml"
require "colorize"
require "em-synchrony"
require "em-synchrony/em-http"
require "faraday"
require "faraday_middleware"
require "faye/websocket"
require "bigdecimal"
require "bigdecimal/util"

require "binance"
require "bitx"
require "peatio"

module Arke; end

require "arke/helpers/precision"
require "arke/helpers/commands"
require "arke/helpers/splitter"
require "arke/helpers/spread"
require "arke/helpers/flags"
require "arke/helpers/orderbook"

require "arke/configuration"
require "arke/log"
require "arke/reactor"
require "arke/exchange"
require "arke/strategy"
require "arke/models/market"
require "arke/models/action"
require "arke/models/order"
require "arke/models/trade"
require "arke/models/price_point"
require "arke/action_executor"
require "arke/scheduler/simple"
require "arke/scheduler/smart"
require "arke/influxdb"
require "arke/etl/reactor"
require "arke/etl/extract/base"
require "arke/etl/extract/ping"
require "arke/etl/extract/binance"
require "arke/etl/extract/amqp"
require "arke/etl/extract/peatio_amqp"
require "arke/etl/extract/tickers"
require "arke/etl/extract/kline"
require "arke/etl/transform/base"
require "arke/etl/transform/debug"
require "arke/etl/transform/sample"
require "arke/etl/transform/generic"
require "arke/etl/load/print"
require "arke/etl/load/amqp"
require "arke/etl/load/peatio_amqp"
require "arke/etl/load/influx"
require "arke/etl/load/kline"
require "arke/etl/load/tickers_writer"
require "arke/influxdb"

require "arke/orderbook/base"
require "arke/orderbook/orderbook"
require "arke/orderbook/aggregated"
require "arke/orderbook/open_orders"

require "arke/strategy/base"
require "arke/strategy/copy"
require "arke/strategy/fixedprice"
require "arke/strategy/microtrades"
require "arke/strategy/orderback"
require "arke/strategy/strategy1"
require "arke/strategy/circuitbraker"

require "arke/exchange/base"
require "arke/exchange/binance"
require "arke/exchange/bitfaker"
require "arke/exchange/bitfinex"
require "arke/exchange/hitbtc"
require "arke/exchange/huobi"
require "arke/exchange/kraken"
require "arke/exchange/luno"
require "arke/exchange/okex"
require "arke/exchange/rubykube"

require "arke/command"
require "arke/command/console"
require "arke/command/etl"
require "arke/command/strategy"
require "arke/command/show"
require "arke/command/start"
require "arke/command/version"
require "arke/command/root"
