# frozen_string_literal: true

module Arke::Plugin
  class LimitBalance < Base
    attr_accessor :account, :base, :quote, :limit_asks_base, :limit_bids_base, :balance_base_perc, :balance_quote_perc

    def initialize(account, base, quote, params)
      @account = account
      @base = base
      @quote = quote
      @limit_asks_base = params["limit_asks_base"]&.to_d
      @limit_bids_base = params["limit_bids_base"]&.to_d
      @balance_base_perc = params["balance_base_perc"]&.to_d
      @balance_quote_perc = params["balance_quote_perc"]&.to_d
      @disable_balance_check = account.opts["disable_balance_check"] ? true : false

      super("LimitBalance (#{@account.id})", params)
    end

    def check_config(params)
      raise "limit_asks_base or balance_base_perc must be specified" if @limit_asks_base.nil? && @balance_base_perc.nil?
      raise "limit_asks_base must be higher than zero" if !@limit_asks_base.nil? && @limit_asks_base <= 0
      raise "balance_base_perc must be higher than 0 to 1" if !@balance_base_perc.nil? && (@balance_base_perc <= 0 || @balance_base_perc > 1)
      raise "limit_bids_base or balance_quote_perc must be specified" if @limit_bids_base.nil? && @balance_quote_perc.nil?
      raise "limit_bids_base must be higher than zero" if !@limit_bids_base.nil? && @limit_bids_base <= 0
      raise "balance_quote_perc must be higher than 0 to 1" if !@balance_quote_perc.nil? && (@balance_quote_perc <= 0 || @balance_quote_perc > 1)
    end

    def call(orderbook)
      top_ask = orderbook[:sell].first
      top_bid = orderbook[:buy].first
      raise "Source order book is empty" if top_ask.nil? || top_bid.nil?

      top_ask_price = top_ask.first
      top_bid_price = top_bid.first
      mid_price = (top_ask_price + top_bid_price) / 2

      quote_balance = @account.balance(@quote)["total"]
      base_balance = @account.balance(@base)["total"]
      limit_bids_quote = quote_balance
      target_base_total = base_balance
      limit_asks_base_applied = @limit_asks_base
      limit_bids_base_applied = @limit_bids_base

      if @disable_balance_check
        return {
          mid_price: mid_price,
          top_bid_price: top_bid_price,
          top_ask_price: top_ask_price,
          limit_bids_base: limit_bids_base_applied,
          limit_asks_base: limit_asks_base_applied,
          limit_bids_quote: nil,
          limit_asks_quote: nil
        }
      end

      # Adjust bids/asks limit by balance ratio.
      if !@balance_quote_perc.nil? && @balance_quote_perc > 0
        limit_bids_quote = quote_balance * @balance_quote_perc
        limit_bids_base_applied = limit_bids_quote / mid_price if @limit_bids_base.nil?
      end
      if !@balance_base_perc.nil? && @balance_base_perc > 0
        target_base_total = base_balance * @balance_base_perc
        limit_asks_base_applied = target_base_total if @limit_asks_base.nil?
      end

      # Adjust bids/asks limit if it exceeded the target (balance).
      if target_base_total < limit_asks_base_applied
        limit_asks_base_applied = target_base_total
        @logger.warn("#{@base} balance on #{@account.driver} is #{target_base_total} lower than the limit set to #{@limit_asks_base}")
      end
      if limit_bids_quote < limit_bids_base_applied * mid_price
        limit_bids_base_applied = limit_bids_quote / mid_price
        @logger.warn("#{@base} balance on #{@account.driver} is #{limit_bids_quote} lower than the limit set to #{@limit_bids_base}")
      end

      limit_asks_quote = target_base_total * mid_price
      {
        mid_price: mid_price,
        top_bid_price: top_bid_price,
        top_ask_price: top_ask_price,
        limit_bids_base: limit_bids_base_applied,
        limit_asks_base: limit_asks_base_applied,
        limit_bids_quote: limit_bids_quote,
        limit_asks_quote: limit_asks_quote
      }
    end

  end
end
