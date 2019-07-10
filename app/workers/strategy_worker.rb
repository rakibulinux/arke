require 'arke'

class StrategyWorker

  def initialize
    @config = []
  end

  def load_db
    @config.concat Strategy.all.map(&:to_h)
  end

  def run
    Arke::Reactor.new(@config).run
  end
end
