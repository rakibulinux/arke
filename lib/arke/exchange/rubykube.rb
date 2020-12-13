# frozen_string_literal: true

module Arke::Exchange
  class Rubykube < Opendax

    def initialize(config)
      super
      logger.warn "rubykube driver is deprecated, use opendax or finex instead"
    end
  end
end