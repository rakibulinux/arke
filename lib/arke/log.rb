# frozen_string_literal: true

require "logger"

module Arke
  # Holds Arke apllication logger
  module Log
    class << self
      # Inits logger
      def define(output=STDERR)
        @logger ||= Logger.new(output)
      end

      def logger
        @logger || define()
      end

      def wrap_block(color, &block)
        block ? proc { block.call.send(color) } : nil
      end

      # Logs +DEBUG+ message
      def debug(message=nil, &block)
        logger.debug(message, &block)
      end

      # Logs +INFO+ message
      def info(message=nil, &block)
        logger.info(message&.blue, &block)
      end

      # Logs +WARN+ message
      def warn(message=nil, &block)
        logger.warn(message&.yellow, &wrap_block(:yellow, &block))
      end

      # Logs +ERROR+ message
      def error(message=nil, &block)
        logger.error(message&.red, &wrap_block(:red, &block))
      end

      # Logs +FATAL+ message
      def fatal(message=nil, &block)
        logger.fatal(message&.red, &wrap_block(:red, &block))
      end

      def level=(severity)
        logger.level = severity
      end
    end
  end

  # class used to dispatch logs to multi reader
  class DispatchDevice
    def initialize
      @devices = {}
    end

    def add_listenner(id, dev)
      @devices[id] = dev
    end

    def remove_listenner(id)
      @devices.delete(id)
    end

    def write(message)
      @devices.each do |_id, dev|
        dev.write(message)
      end
    end

    def close
      @devices.each do |_id, dev|
        dev.close
      end
    end
  end
end
