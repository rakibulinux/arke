# frozen_string_literal: true

module Arke::Command
  class Root < ::Clamp::Command
    subcommand "start", "Starting the bot", Start
    subcommand "recorder", "Manager recording", Recorder
    subcommand "console", "Start a development console", Console
    subcommand "strategy", "Strategies subcommands", Strategy
    subcommand "show", "Show accounts informations", Show
    subcommand "version", "Print the Arke version", Version
  end
end
