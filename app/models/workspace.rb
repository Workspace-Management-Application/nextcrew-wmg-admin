class Workspace < ApplicationRecord
  has_many :company_workspaces
  has_many :companies, through: :company_workspaces
  # has_many :user_workspaces
  # has_many :users, through: :user_workspaces
  # has_many :rooms
  # has_many :day_passes
  # has_many :visitor_entries
  # has_many :office_enquiries
end
