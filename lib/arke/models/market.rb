# frozen_string_literal: true

class Arke::Market
  include Arke::Helpers::Flags

  attr_reader :base, :quote, :amount_precision, :price_precision
  attr_reader :min_amount, :account, :id, :reverse, :logger
  attr_accessor :open_orders

  def initialize(market_id, account, mode=0x0, reverse=false)
    raise "missing market_id" unless market_id

    @id = market_id
    @account = account
    @logger = Arke::Log
    market_config = account.market_config(@id)
    @base = market_config["base_unit"]
    @quote = market_config["quote_unit"]
    @amount_precision = market_config["amount_precision"]
    @price_precision = market_config["price_precision"]
    @min_amount = market_config["min_amount"]
    @open_orders = Arke::Orderbook::OpenOrders.new(id)
    @orderbook = Arke::Orderbook::Orderbook.new(id)
    @reverse = reverse
    apply_flags(mode)
    @private_trades_cb = []
    register_callbacks
  end

  def check_config
    raise "market id must be lowercase for this exchange" if account.flag?(FORCE_MARKET_LOWERCASE) && id != id.downcase
    raise "amount_precision is missing in market #{id} configuration" if flag?(WRITE) && @amount_precision.nil?
    raise "price_precision is missing in market #{id} configuration" if flag?(WRITE) && @price_precision.nil?
    raise "min_amount is missing in market #{id} configuration" if flag?(WRITE) && @min_amount.nil?
  end

  def apply_flags(flags)
    @mode ||= 0
    @mode |= flags
    account.apply_flags(flags)
  end

  def start
    check_config
    fetch_openorders if flag?(FETCH_PRIVATE_OPEN_ORDERS)
  end

  # Fetch the orderbook through REST API and return it
  def update_orderbook
    @orderbook = @account.update_orderbook(id)
  end

  def orderbook
    @reverse ? @orderbook.reverse : @orderbook
  end

  # Return the current state of the orderbook received by websocket
  def realtime_orderbook
    book = account.books[id]&.fetch(:book)
    @reverse ? book.reverse : book
  end

  def register_on_private_trade_cb(&cb)
    @private_trades_cb << cb
  end

  def register_callbacks
    account.register_on_created_order(&method(:add_order))
    account.register_on_deleted_order(&method(:remove_order))
    account.register_on_private_trade_cb(&method(:on_private_trade))
  end

  def add_order(order)
    if order.market.upcase == id.upcase
      logger.debug { "Order created market:#{id} order:#{order}" }
      @open_orders.add_order(order)
    else
      logger.debug { "Order skipped market:#{id} order:#{order}" }
    end
  end

  def remove_order(order)
    if order.market.upcase == id.upcase && @open_orders.exist?(order.side, order.price, order.id)
      @open_orders.remove_order(order.id)
    end
  end

  def create_orders(orders, requestor_id)
    actions = []
    orders.each do |order|
      if @reverse
        price = 1.to_d / order.price
        amount = order.price * order.amount
        side = order.side.to_sym == :sell ? :buy : :sell
        order = ::Arke::Order.new(id, price, amount, side, order.type)
      end
      actions << Arke::Action.new(:order_create, self, order: order)
    end
    account.executor.push(requestor_id, actions)
  end

  def on_private_trade(trade)
    if trade.market.upcase != id.upcase
      logger.debug { "ID:#{id} markets ids don't match #{trade.market.upcase} != #{id.upcase}, ignoring trade..." }
      return
    end
    if @reverse
      price = 1.to_d / trade.price
      amount = trade.price * trade.volume
      total = trade.volume
      trade = ::Arke::Trade.new(trade.id, trade.market, trade.type, amount, price, total, trade.order_id)
    end
    @private_trades_cb.each {|cb| cb&.call(trade) }
  end

  def fetch_balances
    account.fetch_balances
  end

  def fetch_openorders
    open_orders.clear
    account.fetch_openorders(id).each do |order|
      open_orders.add_order(order) unless order.nil?
    end
  end

  def stop_order(order)
    return account.stop_order(order) if order.market.upcase == id.upcase
    nil
  end

  def cancel_all_orders
    account.cancel_all_orders(id)
  end
end
