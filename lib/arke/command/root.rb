# frozen_string_literal: true

module Arke::Command
  class Root < ::Clamp::Command
    subcommand "start", "Start the bot", Start
    subcommand "server", "Start websocket server", Server
    subcommand "show", "Show accounts informations", Show
    subcommand "order", "Create an order using an account", Order
    subcommand "version", "Print the Arke version", Version
  end
end
