require 'rails_helper'

RSpec.describe Ticker, type: :model do
  it { should validate_numericality_of(:mid) }

  it { should validate_numericality_of(:bid) }
  
  it { should validate_numericality_of(:ask) }
  
  it { should validate_numericality_of(:last) }
  
  it { should validate_numericality_of(:low) }
  
  it { should validate_numericality_of(:high) }
  
  it { should validate_numericality_of(:volume) }

  context "validations" do
    let(:ticker) { create(:ticker)}
    
    let(:valid_attributes) do
      {
        market_id: ticker.market_id,
        mid: 3538.43,
        bid: 3543.48,
        ask: 3543.52,
        last: 3543.50,
        low: 3541.98,
        high: 3556.78,
        volume: 0.78
      }
    end

    it "create valid record" do
      record = Ticker.new(valid_attributes)
      expect(record.save).to be_truthy
    end
  end
end
