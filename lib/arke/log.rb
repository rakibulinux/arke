require 'logger'

module Arke
  # Holds Arke apllication logger
  module Log
    class << self
      # Inits logger
      def define(output = STDERR)
        @logger ||= Logger.new(output)
      end

      def logger
        @logger || define()
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
        logger.warn(message&.yellow, &block)
      end

      # Logs +ERROR+ message
      def error(message=nil, &block)
        logger.error(message&.red, &block)
      end

      # Logs +FATAL+ message
      def fatal(message=nil, &block)
        logger.fatal(message&.red, &block)
      end

      def level=(severity)
        logger.level = severity
      end
    end
  end
end
