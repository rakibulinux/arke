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
      def debug(message)
        logger.debug message
      end

      # Logs +INFO+ message
      def info(message)
        logger.info message.to_s.blue
      end

      # Logs +WARN+ message
      def warn(message)
        logger.warn message.to_s.yellow
      end

      # Logs +ERROR+ message
      def error(message)
        logger.error message.to_s.red
      end

      # Logs +FATAL+ message
      def fatal(message)
        logger.fatal message.to_s.red
      end

      def level=(severity)
        logger.level = severity
      end
    end
  end
end
