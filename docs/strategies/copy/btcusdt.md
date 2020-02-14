```yml
log_level: INFO                       # Level of Arke log info

accounts:
#---------------------------{source}-----------------------------------
- id: bitfinex_source                 # Unique account id of the source
  driver: bitfinex                    # One of supported sources drivers
  delay: 1                            # Delay of balance information update
  key: ""                             # API key from source (not required for copy strategy)
  secret: ""                          # Secret from API key from source (not required for copy strategy)

#---------------------------{target}-----------------------------------
- id: rubykube_target                 # Unique account id of the target
  driver: rubykube                    # Only supported target driver
  key: ""                             # API key from the target, required
  secret: ""                          # Secret from API key from the target, required
  host: "https://demo.openware.work"  # Your target URL
  ws: "wss://demo.openware.work"      # Your target WebSocet URL

strategies:
#---------------------------{strategy}-----------------------------------
- id: copy-BTCUSD                     # Name of a strategy
  type: copy                          # Type of the strategy
  debug: false                        # True to see extra Arke logs
  enabled: true                       # True to run this strategy after Arke (re)startgit 
  period: 90                          # Period of order book refresh
  params:
    spread_bids: 0.015                # Percentage difference from the best price on buy side
    spread_asks: 0.015                # Percentage difference from the best price on sell side
    limit_asks_base: 0.08             # The amount of base currency that will be placed for sale in the order book, if have enough balance
    limit_bids_base: 0.08             # The amount of base currency that will be placed for buy in the order book, if have enough balance in quote currency equivalent
    max_amount_per_order: 0.014       # Limit amount of base currency per order (the small amount are, the bigger number of orders at the same price will be created)
    levels_size: 1                    # Minimum price difference between price points
    levels_count: 10                  # Maximum amount of price points that may be created 
    side: both                        # Side, ask, bid or both to apply the strategy on
  target:                           
    account_id: rubykube_target       # Unique account id, from the account section, that will be used as a target (your exchange)
    market_id: btcusd                 # Market pair code in lowercase, from your target exchange
  sources:
  - account_id: bitfinex_source       # Unique account id, from the account section, that will be used as a source
    market_id: BTCUSDT                # Market pair code in uppercase, from you source exchange