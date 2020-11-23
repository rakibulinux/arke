# frozen_string_literal: true

module Arke::Strategy
  # * create random market orders
  # * the order amount is random from the min amount of the market and up to 2 times the min amount
  class CandleSampling < Base
    include ::Arke::Helpers::Orderbook
    include ::Arke::Helpers::Spread
    class EmptyOrderBook < StandardError; end

    def initialize(sources, target, config, reactor)
      super
      params = @config["params"] || {}
      @sampling_ratio = params["sampling_ratio"].to_d
      @max_slippage = params["max_slippage"]&.to_d
      check_config
      logger.info "ID:#{id} Ratio: #{@sampling_ratio}"
      logger.info "ID:#{id} Max Slippage: #{@max_slippage}"

      config_markets
      set_next_threashold
    end

    def delay_the_first_execute
      true
    end

    def config_markets
      sources.each do |s|
        s.apply_flags(::Arke::Helpers::Flags::LISTEN_PUBLIC_TRADES)
        s.account.add_market_to_listen(s.id)
        s.account.register_on_public_trade_cb(&method(:on_trade))
      end
      target.apply_flags(::Arke::Helpers::Flags::LISTEN_PUBLIC_ORDERBOOK)
      target.account.add_market_to_listen(target.id)
    end

    def check_config
      raise "ID:#{id} sampling_ratio must be bigger than zero" unless @sampling_ratio.positive?
      raise "ID:#{id} max_slippage must be lower than one" if @max_slippage && @max_slippage > 1
      raise "ID:#{id} max_slippage must be bigger than zero" if @max_slippage&.negative?
    end

    #
    # Randomize the number of trade we wait to copy
    # This avoid the strategy to be deterministic
    # Set the next threshold to +- 10% of the configured sampling_ratio
    #
    def set_next_threashold
      @events_count = 0
      @next_threashold = (@sampling_ratio * (1 + Random.rand(0.20) - 0.1)).to_i
      logger.info "ID:#{id} Next trade in #{@next_threashold} events"
    end

    def get_amount(side, amount)
      return amount if @max_slippage.nil?

      best_price, stop_price = nil
      safe_amount = 0.to_d
      match_side = opposite_side(side)
      target.realtime_orderbook[match_side].each do |price, volume|
        if best_price.nil?
          best_price = price
          stop_price = apply_spread(match_side, price, @max_slippage)
        end
        break if better(match_side, stop_price, price)

        safe_amount += volume
      end
      [amount, safe_amount].min
    end

    # <struct Arke::PublicTrade
    #   id =           429782187,
    #   market =       BTCUSDT",
    #   exchange =     binance",
    #   taker_type =   buy",
    #   amount =       0.8e-2,
    #   price =        0.1858001e5,
    #   total =        0.14864008e3,
    #   created_at =   1605952875983>
    def on_trade(trade)
      @events_count += 1
      return if @events_count != @next_threashold

      set_next_threashold

      Fiber.new do
        side = trade.taker_type.to_sym
        order = Arke::Order.new(target.id, 0, get_amount(side, trade.amount), side, "market")
        order.apply_requirements(target.account)
        logger.warn "ID:#{id} Creating order #{order}"
        order = target.account.create_order(order)
        logger.warn "ID:#{id} Created order #{order}"
      rescue StandardError => e
        logger.error "ID:#{id} #{e}"
        logger.error e.backtrace.join("\n").to_s
      end.resume
    end

    def call
      # No nothing
    end
  end
end
