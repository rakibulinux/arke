# frozen_string_literal: true

class Arke::Market
  include Arke::Helpers::Flags

  attr_reader :base, :quote, :base_precision, :quote_precision
  attr_reader :min_ask_amount, :min_bid_amount, :account, :id, :orderbook
  attr_accessor :open_orders

  def initialize(market, account, mode=0x0)
    @id = market["id"]
    @account = account
    @base = market["base"]
    @quote = market["quote"]
    @base_precision = market["base_precision"]
    @quote_precision = market["quote_precision"]
    @min_ask_amount = market["min_ask_amount"]
    @min_bid_amount = market["min_bid_amount"]
    @open_orders = Arke::Orderbook::OpenOrders.new(id)
    @orderbook = Arke::Orderbook::Orderbook.new(id)
    apply_flags(mode)
    register_callbacks
  end

  def check_config
    if account.flag?(FORCE_MARKET_LOWERCASE)
      raise "market id must be lowercase for this exchange" if id != id.downcase
      raise "market base currency must be lowercase for this exchange" if base != base.downcase
      raise "market quote currency must be lowercase for this exchange" if quote != quote.downcase
    end
    raise "base_precision is missing in market #{id} configuration" if flag?(WRITE) && @base_precision.nil?
    raise "quote_precision is missing in market #{id} configuration" if flag?(WRITE) && @quote_precision.nil?
    raise "min_ask_amount is missing in market #{id} configuration" if flag?(WRITE) && @min_ask_amount.nil?
    raise "min_bid_amount is missing in market #{id} configuration" if flag?(WRITE) && @min_bid_amount.nil?
  end

  def apply_flags(flags)
    @mode ||= 0
    @mode |= flags
    account.apply_flags(flags)
  end

  def start
    check_config
    if flag?(FETCH_PRIVATE_OPEN_ORDERS)
      fetch_openorders
    end
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
      Arke::Log.debug "Order created market:#{id} order:#{order}"
      @open_orders.add_order(order)
    else
      Arke::Log.debug "Order skipped market:#{id} order:#{order}"
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
    account.stop_order(order) if order.market.upcase == id.upcase
  end

  def cancel_all_orders
    account.cancel_all_orders(id)
  end
end
