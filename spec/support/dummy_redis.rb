# encoding: UTF-8
# frozen_string_literal: true

class DummyRedis
  def initialize
    @messages = {}
    @keys = {}
  end

  def publish(channel, data)
    @messages.store(channel, data)
  end

  def set(key, value)
    @keys.store(key,value)
  end

  def get(key)
    @keys[key]
  end

  def trigger_on
    @block.call make_on_message
  end

  def get_message(channel)
    @messages[channel]
  end
end
