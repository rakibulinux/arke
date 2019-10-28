# frozen_string_literal: true

module Arke::ETL::Extract
  class Ping < Base
    def start
      EM::Synchrony.add_periodic_timer(1) do
        emit("ping")
      end
    end
  end
end
