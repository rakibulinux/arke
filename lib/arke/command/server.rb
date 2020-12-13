# frozen_string_literal: true

module Arke::Command
  class Server < ::Clamp::Command
    include Arke::Helpers::Commands
    def execute
      ::Arke::Server.new.run
    end
  end
end
