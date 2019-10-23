class Robot < ApplicationRecord
  belongs_to :user

  #TODO link to credentials id
  has_and_belongs_to_many :accounts

  STRATEGY_NAMES = %w[copy orderback fixedprice microtrades].freeze
  STATES = %w[enabled disabled].freeze
  validates :name, :strategy,
            :state, presence: true
  
  validates :strategy, inclusion: {in: STRATEGY_NAMES}
  validates :state, inclusion: {in: STATES}

end
