# frozen_string_literal: true

module Arke::Strategy

  class CandleSampling < Base
    include ::Arke::Helpers::Orderbook
    include ::Arke::Helpers::Spread
    class EmptyOrderBook < StandardError; end

    def initialize(sources, target, config, reactor)
      super
      params = @config["params"] || {}
      @sampling_ratio = params["sampling_ratio"].to_d
      @max_slippage = params["max_slippage"]&.to_d
      @max_balance = params["max_balance"]&.to_d

      check_config
      logger.info "ID:#{id} Ratio: #{@sampling_ratio}"
      logger.info "ID:#{id} Max Slippage: #{@max_slippage}"
      logger.info "ID:#{id} Max Balance: #{@max_balance}"

      config_markets
      set_next_threashold
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
      raise "ID:#{id} max_balance must be lower than one" if @max_balance && @max_balance > 1
      raise "ID:#{id} max_balance must be bigger than zero" if @max_balance&.negative?
    end

    #
    # Randomize the number of trade we wait to copy
    # This avoid the strategy to be deterministic
    # Set the next threshold to +- 10% of the configured sampling_ratio
    #
    def set_next_threashold
      @events_count = 0
      @price_open = @price_close
      @price_close = nil
      @volume = 0.to_d
      @next_threashold = (@sampling_ratio * (1 + Random.rand(0.20) - 0.1)).to_i
      logger.info "ID:#{id} Next trade in #{@next_threashold} events"
    end

    def limit_amount_by_balance(side, amount)
      return amount if @max_balance.nil?

      case side
      when :buy
        currency = target.quote
        best_sell = target.realtime_orderbook.best_price(:sell)
        raw_estimate = amount * best_sell
      when :sell
        currency = target.base
        raw_estimate = amount
      else
        raise "Invalid side #{side.inspect}"
      end

      balance = target.account.balance(currency)&.fetch("free")
      raise "ID:#{id} No balance found for currency #{currency}" unless balance

      if raw_estimate > @max_balance * balance
        if side == :buy
          return (@max_balance * balance) / best_sell
        else
          return @max_balance * balance
        end
      end
      amount
    end

    def limit_amount_by_price_slippage(side, amount)
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
      logger.info "ID:#{id} limiting the trade amount to avoid price slipage" if safe_amount < amount
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
      @price_open = trade.price if @price_open.nil?
      @price_close = trade.price
      @volume += trade.amount
      return if @events_count != @next_threashold

      side = @price_close > @price_open ? :buy : :sell

      amount = @volume / @events_count
      amount = limit_amount_by_balance(side, amount)
      amount = limit_amount_by_price_slippage(side, amount)

      Fiber.new do
        order = Arke::Order.new(target.id, 0, amount, side, "market")

        order.apply_requirements(target.account)
        logger.warn "ID:#{id} Creating order #{order}"
        order = target.account.create_order(order)
        logger.warn "ID:#{id} Created order #{order}"
      rescue StandardError => e
        logger.error "ID:#{id} #{e}"
        logger.error e.backtrace.join("\n").to_s
      end.resume

      set_next_threashold
    end

    # def compute_ratio
    #   source_volume = source.orderbook.volume_bids_base + source.orderbook.volume_asks_base
    #   target_volume = target.realtime_orderbook.volume_bids_base + target.realtime_orderbook.volume_asks_base
    #   @orderbooks_ratio = source_volume / target_volume
    # end

    def call
      # Noop
    end
  end
end
