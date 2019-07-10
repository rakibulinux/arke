require 'rails_helper'

RSpec.describe StrategyWorker, type: :worker do
  context 'Perfoming tasks' do

    it 'loads strategies from db' do
      skip
      expect { StrategyWorker.new.load_db }.not_to raise_error
    end
  end
end
