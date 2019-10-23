# frozen_string_literal: true

module Arke::Command
  class Recorder < Clamp::Command
    class Start < Clamp::Command
      include Arke::Helpers::Commands
      option "--output-dir", "PATH", "Output store directory", default: "data"
      option "--config", "FILE_PATH", "Strategies config file", default: "config/recorder.yml"
      option "--dry", :flag, "dry run on the target"

      def execute
        Arke::Log.level = Logger::Severity.const_get(conf["log_level"].upcase || "INFO")
        Arke::Recorder::Reactor.new(conf(), dry?).run
      end
    end

    subcommand "start", "Start recording", Start
  end
end
