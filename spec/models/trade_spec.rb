require 'rails_helper'

RSpec.describe Trade, type: :model do
 
  it { should validate_numericality_of(:side) }

  it { should validate_numericality_of(:price) }
  
  it { should validate_numericality_of(:amount) }
  
  it { should validate_numericality_of(:fee) }
  
  context "validations" do
    let(:trade) { build(:trade)}
    
    let(:valid_attributes) do
      {
        account_id: trade.account_id,
        market_id: trade.market_id,
        tid: trade.tid,
        side: 1,
        price: 2435.87,
        amount: 0.78,
        fee: 0.15
      }
    end

    it "create valid record" do
      record = Trade.new(valid_attributes)
      expect(record.save).to be_truthy
    end
  end
end
