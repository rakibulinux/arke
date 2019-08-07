# frozen_string_literal: true

require "arke"

class StrategyWorker
  attr_reader :config

  def initialize
    @config = []
  end

  def load_db
    @config.concat Strategy.all.map(&:to_h)
  end

  def load_file(file)
    @config = YAML.load_file(file)["strategies"]
  end

  def run
    Arke::Reactor.new(@config).run
  end
end
