class Trade < ApplicationRecord
  belongs_to :credential
  belongs_to :market
end
