require 'rails_helper'

RSpec.describe StrategyWorker, type: :worker do
  context 'Perfoming tasks' do

    it 'be able to start strategies' do
      sw = StrategyWorker.new
      sw.perform('start', 10)
      sw.wait
    end
  end
end
