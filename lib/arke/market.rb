# frozen_string_literal: true

class Arke::Market
  attr_reader :base, :quote, :base_precision, :quote_precision
  attr_reader :min_ask_amount, :min_bid_amount, :account, :id, :orderbook
  attr_accessor :open_orders

  DEFAULT_BASE_PRECISION = 8
  DEFAULT_QUOTE_PRECISION = 8

  def initialize(market, account)
    @id = market["id"]
    @account = account
    @base = market["base"]
    @quote = market["quote"]
    @base_precision = market["base_precision"] || DEFAULT_BASE_PRECISION
    @quote_precision = market["quote_precision"] || DEFAULT_QUOTE_PRECISION
    @min_ask_amount = market["min_ask_amount"]
    @min_bid_amount = market["min_bid_amount"]
    @open_orders = Arke::Orderbook::OpenOrders.new(id)
    @orderbook = Arke::Orderbook::Orderbook.new(id)
    register_callbacks
  end

  def start
    @account.fetch_openorders(id).each do |o|
      @open_orders.add_order(o)
    end

    update_orderbook
    @account.start
  end

  def update_orderbook
    @orderbook = @account.update_orderbook(id)
  end

  def register_callbacks
    account.register_on_created_order(&method(:add_order))
    account.register_on_deleted_order(&method(:remove_order))
  end

  def add_order(order)
    @open_orders.add_order(order) if order.market.upcase == id.upcase
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
