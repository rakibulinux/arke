# frozen_string_literal: true

module Arke::Fx
  class Fixer < Static
    DEFAULT_PERIOD = 3600
    attr_reader :logger, :period, :currency_from, :currency_to

    def initialize(config)
      @logger = Arke::Log
      @period = config["period"]&.to_i || DEFAULT_PERIOD
      @api_key = config["api_key"]
      @https = config["https"] != false
      @currency_from = config["currency_from"]
      @currency_to = config["currency_to"]
      @debug = config["debug"] == true
      @adapter = config[:faraday_adapter] || :em_synchrony
      check_config
    end

    def start
      @cnx = Faraday.new(url: "%s://data.fixer.io/api" % [@https ? "https" : "http"]) do |builder|
        builder.response :json
        builder.response :logger if @debug
        builder.adapter(@adapter)
      end
      fetch_rate
      EM::Synchrony.add_periodic_timer(period) { fetch_rate }
    end

    def fetch_rate
      raise "Fixer has not been started" unless @cnx

      params = {
        access_key: @api_key,
        base:       currency_from,
        symbols:    currency_to
      }
      data = @cnx.get("latest", params)
      if data.body["success"]
        @rate = data.body["rates"]&.fetch(currency_to)
        logger.info { "Rate #{currency_to}#{@currency_from} fetched: #{rate}" }
      else
        logger.error "Fixer rate fetching failed: #{data.body['error']}"
      end
    end

    def check_config
      raise "currency_from is missing" if currency_from.to_s.empty?
      raise "currency_to is missing" if currency_to.to_s.empty?
      raise "invalid refresh period" if period <= 0
    end
  end
end
