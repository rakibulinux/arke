# frozen_string_literal: true

module Arke::Strategy
  class Arbitrage < Base
    include ::Arke::Helpers::Spread
    include ::Arke::Helpers::Flags

    def initialize(sources, target, config, reactor)
      super
      params = @config["params"] || {}

      @profit = params["profit"] || 0.0005
      @min_amount = params["min_amount"]
      @dry_run = params["dry_run"] == true
      @max_amount_perc = params["max_amount_perc"] || 0.1

      check_config
      config_markets

      logger.info "ID:#{id} Profit: #{@profit}"
      logger.info "ID:#{id} Min Amount: #{@min_amount}"
    end

    def check_config
      raise "ID:#{id} profit must be positive and lower than 10" if @profit.nil? || @profit.negative? || @profit > 10
      raise "ID:#{id} min_amount must be higher than zero" if @min_amount.nil? || @min_amount.negative?
    end

    def config_markets
      sources.each do |s|
        raise "ID:#{id} Please configure `taker_fee` on account #{s.account.id}" unless s.account.opts["taker_fee"]

        s.apply_flags(LISTEN_PUBLIC_ORDERBOOK)
        s.apply_flags(FETCH_PRIVATE_BALANCE)
        s.account.add_market_to_listen(s.id)
      end
    end

    def ask_price_with_taker_fee(price, market)
      price * (1 + market.account.opts["taker_fee"])
    end

    def bid_price_with_taker_fee(price, market)
      price * (1 - market.account.opts["taker_fee"])
    end

    def price_level(a)
      return nil if a.nil?

      ::Arke::PriceLevel.new(a.first, a.last)
    end

    def check_balance(ex, currency)
      balance = ex.account.balance(currency)
      if balance.nil? || balance["free"].zero?
        logger.warn "Empty balance of %s on %s" % [currency, ex.account.id]
      end
    end

    def trigger_orders(s1, s2, top_ask, top_bid, amount)
      bid = Arke::Order.new(s2.id, top_ask.price, amount, :buy, "limit")
      bid.apply_requirements(s2.account)

      ask = Arke::Order.new(s1.id, top_bid.price, amount, :sell, "limit")
      ask.apply_requirements(s1.account)

      # Adjust order amount from other market constraints
      if bid.amount > ask.amount
        ask.amount = bid.amount
        ask.apply_requirements(s1.account)
      elsif bid.amount < ask.amount
        bid.amount = ask.amount
        bid.apply_requirements(s2.account)
      end

      # Final orders amount check
      if (ask.amount - bid.amount).abs / [ask.amount, bid.amount].max > @max_amount_perc
        logger.error("ID:#{id} Order amounts diff more than #{@max_amount_perc * 100}%")
        logger.info("ID:#{id} Order on %s %s: %s" % [s2.account.id, s2.id, bid.to_s])
        logger.info("ID:#{id} Order on %s %s: %s" % [s1.account.id, s1.id, ask.to_s])
        return
      end

      # Final balances check
      b2 = s2.account.balance(s2.quote)
      if b2.nil? || b2["free"] < bid.amount * bid.price
        logger.warn("ID:#{id} Not enough %s to execute %s %s: %s" % [b2.quote, s2.account.id, s2.id, bid.to_s])
        return
      end

      b1 = s1.account.balance(s1.base)
      if b1.nil? || b1["free"] < ask.amount
        logger.warn("ID:#{id} Not enough %s to execute %s %s: %s" % [b1.quote, s1.account.id, s1.id, ask.to_s])
        return
      end

      logger.info("ID:#{id} Submit order on %s %s: %s" % [s2.account.id, s2.id, bid.to_s])
      logger.info("ID:#{id} Submit order on %s %s: %s" % [s1.account.id, s1.id, ask.to_s])

      return if @dry_run

      s1.account.executor.push(id, [Arke::Action.new(:order_create, s1, order: ask)])
      s2.account.executor.push(id, [Arke::Action.new(:order_create, s2, order: bid)])

      EM::Synchrony.add_timer(2) do
        EM.stop
      end
    end

    def call
      raise "ID:#{id} This strategy needs multiple sources" unless sources.size > 1

      markets = {}
      sources.each do |s|
        check_balance(s, s.base)
        check_balance(s, s.quote)

        top_ask = price_level(s.orderbook[:sell].first)
        top_bid = price_level(s.orderbook[:buy].first)
        if top_ask.nil? || top_bid.nil?
          logger.error "ID:#{id} Empty orderbook for #{s.id}"
          next
        end
        markets[s] = {
          top_ask: top_ask,
          top_bid: top_bid,
        }
        logger.debug { "ID:#{id} #{s.account.id} top_ask: %f top_bid: %f" % [top_ask.price, top_bid.price] }
      end

      markets.each do |s1, m1|
        markets.each do |s2, m2|
          next if s1 == s2

          top_bid = m1[:top_bid]
          top_ask = m2[:top_ask]

          profit = bid_price_with_taker_fee(top_bid.price, s1) - ask_price_with_taker_fee(top_ask.price, s2)
          mid_price = (top_bid.price + top_ask.price) / 2
          profit_perc = profit / mid_price * 100

          if profit <= 0
            logger.info("ID:#{id} No profit Bid: %f (%s) <= Ask: %f (%s), profit: %f (%f%%)" % [
              top_bid.price, s1.account.id, top_ask.price, s2.account.id, profit, profit_perc
            ])

          else
            logger.warn("ID:#{id} Arbitrage opportunity %f (%s) > %f (%s), profit: %f (%f%%)" % [
              top_bid.price, s1.account.id, top_ask.price, s2.account.id, profit, profit_perc
            ])

            if profit_perc >= @profit
              logger.warn("ID:#{id} Triggering arbitrage!")

              m1_base = s1.account.balance(s1.base)["free"]
              m2_quote = s2.account.balance(s2.quote)["free"]

              amount = [top_bid.amount, top_ask.amount, m1_base].min

              if top_ask.amount * top_ask.price > m2_quote
                amount = m2_quote / top_ask.price
                logger.info("ID:#{id} %s balance on %s is limiting the amount to %f" % [s2.quote, s2.account.id,
                                                                                        amount])
              end

              if amount < @min_amount
                logger.info("ID:#{id} Amount %f lower than min amount %f, skipping..." % [amount, @min_amount])
                next
              end

              trigger_orders(s1, s2, top_ask, top_bid, amount)

            end
          end
        end
      end

      [nil, nil]
    end
  end
end
