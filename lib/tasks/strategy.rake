namespace :strategy do
  desc 'Start a strategy through sidekiq'
  task :start => :environment do
    StrategyWorker.perform_async(:start, 42)
  end
end
