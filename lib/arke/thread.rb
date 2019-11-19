# frozen_string_literal: true

module Arke
  class Thread
    def run
      ::Thread.new do
        loop do
          yield
        rescue StandardError => e
          ::Rails.logger.error("#{e}: #{e.backtrace.join("\n")}")
          sleep 5
        end
      end
    end

    def on_message(_message)
      raise "on_message method not implemented"
    end
  end
end
