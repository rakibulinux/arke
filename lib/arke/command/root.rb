require 'arke/command/start'
require 'arke/command/console'
require 'arke/command/version'
require 'arke/command/strategy'

module Arke
  module Command
    class Root < ::Clamp::Command
      subcommand 'start', 'Starting the bot', Start
      subcommand 'console', 'Start a development console', Console
      subcommand 'strategy', 'Strategies subcommands', Strategy
      subcommand 'show', 'Show accounts informations', Show
      subcommand 'version', 'Print the Arke version', Version
    end
  end
end
