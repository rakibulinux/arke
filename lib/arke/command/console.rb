# frozen_string_literal: true

module Arke
  module Command
    class Console < Clamp::Command
      def execute
        require "pry"
        Pry.hooks.add_hook(:before_session, "arke_load") do |output, _binding, _pry|
          output.puts "Arke development console"
        end

        # binding.pry
        Pry.config.prompt_name = "arke"
        Pry.config.requires = ["openssl"]
        Pry.start
      end
    end
  end
end
