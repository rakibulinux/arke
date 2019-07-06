class Strategy < ApplicationRecord
  belongs_to :user

  #TODO link to credentials id
  belongs_to :source
  belongs_to :target
end
