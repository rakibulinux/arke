# frozen_string_literal: true

module Arke::Command
  def run!
    load_configuration
    Root.run
  end
  module_function :run!

  def load_configuration
    strategy_file = File.join(__dir__, "../../config/strategies.yml")
    raise "File #{strategy_file} not found" unless File.exist?(strategy_file)

    config = YAML.load_file(strategy_file)

    Arke::Configuration.define {|c| c.strategy = config["strategy"] }
  end
  module_function :load_configuration

  # NOTE: we can add more features here (colored output, etc.)
end
