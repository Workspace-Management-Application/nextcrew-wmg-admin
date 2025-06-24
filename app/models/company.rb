class Company < ApplicationRecord
  # has_many :company_users
  # has_many :users, through: :company_users
  has_many :company_workspaces
  has_many :workspaces, through: :company_workspaces
  # has_many :day_passes

  enum :status, { active: 'active', inactive: 'inactive', pending: 'pending', approved: 'approved' }, default: :pending

  validates :phone_number, uniqueness: true
end
