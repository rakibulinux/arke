require 'rails_helper'

RSpec.describe Robot, type: :model do
  let(:robot) { build(:robot)}

  it { should validate_presence_of(:name) }
  
  it { should validate_presence_of(:strategy) }
  
  it { should validate_presence_of(:state) } 
  
  it { expect(robot).to validate_inclusion_of(:strategy).in_array(Robot::STRATEGY_NAMES) }
  
  it { expect(robot).to validate_inclusion_of(:state).in_array(Robot::STATES) }
  
  context "validations" do
    let(:user) { create(:user) }
    let(:valid_attributes) do
      {
        user_id:         user.id,
        name:            :robot,
        strategy:        :copy,
        state:           :disabled
      }
    end

    it "creates valid record" do
      record = Robot.new(valid_attributes)
      expect(record.save).to be_truthy
    end
   end
end
