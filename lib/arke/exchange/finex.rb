# frozen_string_literal: true

module Arke::Exchange
  class Finex < Opendax

    def initialize(config)
      super
      @finex = true
    end
  end
end
