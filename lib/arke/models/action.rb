# frozen_string_literal: true

module Arke
  # This class represents Actions as jobs which are executed by Exchanges
  class Action
    attr_reader :type, :params, :destination

    def initialize(type, destination, params=nil)
      @type        = type
      @params      = params
      @destination = destination
    end

    def to_s
      "#Action type: #{@type}, params: #{@params}, destination: #{destination}"
    end

    def priority
      @params[:priority]
    end

    alias inspect to_s

    def ==(action)
      (@type == action.type) && \
      @params.map {|k, v| v == action.params[k] }.index(false).nil? && \
      (@destination == action.destination)
    end
  end
end
