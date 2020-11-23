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
#---------------------------{candle-sampling}-----------------------------------
- id: candle-BTCUSD                   # Name of a strategy
  type: candle-sampling               # Type of the strategy
  debug: false                        # True to see extra Arke logs
  enabled: true                       # True to run this strategy after Arke (re)startgit
  period: 1000                        # Ignored
  params:
    sampling_ratio: 1000              # Copy 1 trade every 1000 trades (more or less 10%)
    max_slippage: 0.005               # Reduce trades amount in case of price slippage
  target:
    account_id: rubykube_target       # Unique account id, from the account section, that will be used as a target (your exchange)
    market_id: btcusd                 # Market pair code in lowercase, from your target exchange
