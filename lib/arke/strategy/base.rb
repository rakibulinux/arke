module Arke::Strategy
  # Base class for all strategies
  class Base
    attr_reader :debug_infos, :period, :period_random_delay
    attr_reader :sources, :target, :id

    Sides = %w{asks bids both}

    DefaultOrderbackTimer = 0.01
    DefaultPeriod = 10

    def initialize(sources, target, config, executor, reactor)
      @config = config
      @id = @config["id"]
      @volume_ratio = config["volume_ratio"]
      @spread = config["spread"]
      @precision = config["precision"]
      @debug = !!config["debug"]
      @debug_infos = {}
      @period = (config["period"] || DefaultPeriod).to_f
      @period_random_delay = config["period_random_delay"]
      params = @config["params"] || {}
      @side = Sides.include?(params["side"]) ? params["side"] : "both"
      @enable_orderback = params["enable_orderback"]
      @orderback_timer = params["orderback_timer"] || DefaultOrderbackTimer
      @trades = []
      @executor = executor
      @sources = sources
      @target = target
      @reactor = reactor
      register_callbacks
      Arke::Log.info "ID:#{id} ----====[ #{self.class.to_s.split('::').last} Strategy ]====----"
    end

    def delay_the_first_execute
      false
    end

    def push_debug(step_name, step_data)
      return unless @debug
      @debug_infos[step_name] = step_data
    end

    def assert_currency_found(ex, currency)
      unless ex.balance(currency)
        raise "ID:#{id} Currency #{currency} not found on #{ex.driver}".red
      end
    end

    def register_callbacks
      target.register_on_trade_cb(&method(:order_back))
    end

    def source
      sources.first
    end

    def order_back(trade, order)
      Arke::Log.info("ID:#{id} Trade on #{trade.market}, #{order.side} price: #{trade.price} amount: #{trade.volume}")
      if @enable_orderback
        spread = order.side == :sell ? @spread_asks : @spread_bids
        price = apply_spread(order.side, trade.price, -spread)
        type = order.side == :sell ? :buy : :sell

        Arke::Log.info("ID:#{id} Buffering order back #{trade.market}, #{type} price: #{price} amount: #{trade.volume}")
        @trades << [trade.market, price, trade.volume, type]
        @timer ||= EM::Synchrony.add_timer(@orderback_timer) do
          grouped_trades = group_trades(@trades)
          orders, actions = [], []

          grouped_trades.each do |k, v|
            order = Arke::Order.new(v[0], k[0].to_f, v[1].to_f, k[1].to_sym)
            if order.amount > source.min_order_back_amount
              Arke::Log.info("ID:#{id} Pushing order back #{order} (source.min_order_back_amount: #{source.min_order_back_amount})")
              orders << order
            else
              Arke::Log.info("ID:#{id} Discard order back #{order} (source.min_order_back_amount: #{source.min_order_back_amount})")
            end
          end

          orders.each do |order|
            actions << Arke::Action.new(:order_create, source, { order: order })
          end
          @executor.push(actions)
          @timer = nil
          @trades = []
        end
      end
    end

    def group_trades(trades)
      group = trades.group_by { |t| [t[1], t[3]] }
      group.each do |k, v|
        volume = 0
        v.each { |a| volume += a[2] }
        group[k] = [v.first[0], volume]
      end
    end
  end
end
