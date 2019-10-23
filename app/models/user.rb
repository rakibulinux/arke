class User < ApplicationRecord
  has_many :accounts
  has_many :robots

  validates :uid, presence: true, length: { maximum: 12 }, uniqueness: { case_sensitive: true}
  validates :email, presence: true, format: { with: /[\w._%+-]+@[\w.-]+\.[a-zA-z]{2,4}\Z/ }, uniqueness: { case_sensitive: true}
  validates :level, presence: true, numericality: {only_integer: true, greater_than_or_equal_to: 1, less_than_or_equal_to: 4}
  validates :role, presence: true, inclusion: { in: %w(admin trader broker),
                                                    message: "%{value} is not a valid role" }
  validates :state, presence: true, inclusion: { in: %w(active disabled),
                                                     message: "%{value} is not a valid state" }
  validates :created_at, presence: true
end
