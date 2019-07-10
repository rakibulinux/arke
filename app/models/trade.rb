class Trade < ApplicationRecord
  belongs_to :account
  belongs_to :market
end
