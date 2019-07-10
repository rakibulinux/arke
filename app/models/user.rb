class User < ApplicationRecord
  has_many :accounts
  has_many :strategies
end
