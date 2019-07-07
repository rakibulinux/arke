require 'arke'

class StrategyWorker
  include Sidekiq::Worker

  def initialize
    @threads ||= []
  end

  def perform(command, id)

    case command
    when 'start'
      logger.warn "Starting #{id}"
      @threads << Thread.new { Arke::Reactor.new({}).run }
    else
    end
  end

  def wait
    @threads.each(&:join)
  end
end
