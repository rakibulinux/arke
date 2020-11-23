# frozen_string_literal: true

module Arke::Strategy
  class MicrotradesCopy < Base
    include ::Arke::Helpers::Precision
    include ::Arke::Helpers::Spread
    include ::Arke::Helpers::Orderbook

    class EmptyOrderBook < StandardError; end

    def initialize(sources, target, config, reactor)
      super
      @sampling_delay = @period || 60
      @sampling_random_delay = @period_random_delay
      @sampling_random_delay ||= @sampling_random_delay * 0.1

      @period = 60
      @period_random_delay = nil

      params = @config["params"] || {}
      @matching_timeout = (params["matching_timeout"]&.to_f || 1.0)
      @maker_taker_orders_delay = (params["maker_taker_orders_delay"]&.to_f || 0.02)
      @min_amount = (params["min_amount"] || target.min_amount).to_f
      @max_amount = (params["max_amount"] || @min_amount * 10).to_f

      logger.info "ID:#{id} Min amount: #{@min_amount}"
      logger.info "ID:#{id} Max amount: #{@max_amount}"
      logger.info "ID:#{id} Sampling delay: #{@sampling_delay}"
      logger.info "ID:#{id} Sampling random delay: #{@sampling_random_delay}"

      check_config
      config_markets
      set_current_expiration
    end

    def config_markets
      sources.each do |s|
        s.apply_flags(::Arke::Helpers::Flags::LISTEN_PUBLIC_TRADES)
        s.account.add_market_to_listen(s.id)
        cb = proc {|trade| on_trade(s.id, trade) }
        s.account.register_on_public_trade_cb(&cb)
      end
      target.apply_flags(::Arke::Helpers::Flags::LISTEN_PUBLIC_ORDERBOOK)
      target.account.add_market_to_listen(target.id)
    end

    def check_config
      raise "ID:#{id} min_amount must be bigger than zero" unless @min_amount.positive?
      raise "ID:#{id} max_amount must be bigger than zero" unless @max_amount.positive?
      raise "ID:#{id} min_amount should be lower than max_amount" if @min_amount > @max_amount
    end

    def set_current_expiration
      current_delay = @sampling_delay + rand() * @sampling_random_delay
      @expiration = Time.now.to_i + current_delay
      logger.info { "ID:#{id} Expiration set in #{current_delay} sec" }
    end

    def call; end

    def get_price(price)
      if fx
        raise "FX Rate is not ready" unless fx.rate

        price * fx.rate
      else
        price
      end
    end

    # TODO: 3- add the support of 2 different accounts
    def trigger_microtrade(trade)
      orders_f = Fiber.new do
        amount = rand(@min_amount.to_f..@max_amount.to_f)
        price = get_price(trade.price)
        ob = target.update_orderbook
        best_buy = ob.best_price(:buy).to_d
        best_sell = ob.best_price(:sell).to_d
        price_min_increment = (10**-target.price_precision).to_f

        if best_sell - best_buy <= price_min_increment
          raise "Spread is too small best_sell: %s, best_buy: %s, price_min_increment: %s" % [best_sell, best_buy, price_min_increment]
        end

        price = best_sell - price_min_increment if price >= best_sell
        price = best_buy + price_min_increment if price <= best_buy

        maker_side = opposite_side(trade.taker_type)
        marker = Arke::Order.new(target.id, price, amount, maker_side)
        marker.apply_requirements(target.account)
        logger.warn "ID:#{id} Pushing order #{marker}"
        target.account.create_order(marker)

        EM::Synchrony.sleep(@maker_taker_orders_delay)
        taker_side = trade.taker_type.to_sym
        taker = Arke::Order.new(target.id, price, amount, taker_side)
        taker.apply_requirements(target.account)
        logger.warn "ID:#{id} Pushing order #{taker}"
        target.account.create_order(taker)

        EM::Synchrony.sleep(@matching_timeout)
        [maker_side, taker_side].each do |side|
          target.open_orders[side][price]&.each do |id, order|
            logger.error { "ID:#{id} order #{side} is remaining after #{@matching_timeout} sec, canceling order #{order}" }
            target.account.stop_order(order)
          end
        end

      rescue StandardError => e
        logger.error "ID:#{id} #{e}"
        logger.error e.backtrace.join("\n").to_s
      end
      orders_f.resume
    end

    def on_trade(account_market_id, trade)
      if account_market_id.downcase != trade.market.downcase
        logger.debug { "ID:#{id} Trade skipped #{account_market_id}: #{trade}" }
        return
      end
      logger.debug { "ID:#{id} Trade on #{account_market_id}: #{trade}" }

      return unless Time.now.to_i >= @expiration

      logger.info "ID:#{id} Trade on #{account_market_id}: #{trade}"
      trigger_microtrade(trade)
      set_current_expiration
    rescue StandardError => e
      logger.error "ID:#{id} #{e}"
      logger.error e.backtrace.join("\n").to_s
    end
  end
end
