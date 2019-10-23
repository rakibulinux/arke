class Strategy < ApplicationRecord
  belongs_to :user, required: true
  belongs_to :source, class_name: :Account
  belongs_to :target, class_name: :Account
  belongs_to :source_market, class_name: :Market
  belongs_to :target_market, class_name: :Market
end
