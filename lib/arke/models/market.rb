# frozen_string_literal: true

class Arke::Market
  include Arke::Helpers::Flags

  attr_reader :base, :quote, :amount_precision, :price_precision
  attr_reader :min_amount, :account, :id, :orderbook
  attr_accessor :open_orders

  def initialize(market_id, account, mode=0x0)
    raise "missing market_id" unless market_id

    @id = market_id
    @account = account
    market_config = account.market_config(@id)
    @base = market_config["base_unit"]
    @quote = market_config["quote_unit"]
    @amount_precision = market_config["amount_precision"]
    @price_precision = market_config["price_precision"]
    @min_amount = market_config["min_amount"]
    @open_orders = Arke::Orderbook::OpenOrders.new(id)
    @orderbook = Arke::Orderbook::Orderbook.new(id)
    apply_flags(mode)
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

  def update_orderbook
    @orderbook = @account.update_orderbook(id)
  end

  def register_callbacks
    account.register_on_created_order(&method(:add_order))
    account.register_on_deleted_order(&method(:remove_order))
  end

  def add_order(order)
    if order.market.upcase == id.upcase
      Arke::Log.debug { "Order created market:#{id} order:#{order}" }
      @open_orders.add_order(order)
    else
      Arke::Log.debug { "Order skipped market:#{id} order:#{order}" }
    end
  end

  def remove_order(order)
    if order.market.upcase == id.upcase && @open_orders.exist?(order.side, order.price, order.id)
      @open_orders.remove_order(order.id)
    end
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
