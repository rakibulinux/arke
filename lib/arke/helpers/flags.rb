# frozen_string_literal: true

module Arke::Helpers::Flags
  WRITE = 0x1
  WS_PUBLIC = 0x2
  WS_PRIVATE = 0x4
  FETCH_PRIVATE_BALANCE = 0x8
  FETCH_PRIVATE_OPEN_ORDERS = 0x10
  FETCH_PUBLIC_ORDERBOOK = 0x20
  FORCE_MARKET_LOWERCASE = 0x40
  LISTEN_PUBLIC_TRADES = 0x80 | WS_PUBLIC
  LISTEN_PUBLIC_ORDERBOOK = 0x100 | WS_PUBLIC

  DEFAULT_SOURCE_FLAGS = FETCH_PUBLIC_ORDERBOOK
  DEFAULT_TARGET_FLAGS = WRITE | FETCH_PRIVATE_OPEN_ORDERS | FETCH_PRIVATE_BALANCE | WS_PRIVATE

  def flag?(flag)
    @mode ||= 0
    @mode & flag == flag
  end

  def apply_flags(flags)
    @mode ||= 0
    @mode |= flags
  end

  def remove_flags(flags)
    @mode ||= 0
    @mode = @mode & ~flags
  end
end
