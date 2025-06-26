class Workspace < ApplicationRecord
  has_many :company_workspaces,  dependent: :destroy
  has_many :companies, through: :company_workspaces,  dependent: :destroy
  has_many :user_workspaces,  dependent: :destroy
  has_many :users, through: :user_workspaces,  dependent: :destroy
  has_many :rooms,  dependent: :destroy
  has_many :day_passes,  dependent: :destroy
  has_many :visitor_entries,  dependent: :destroy
  has_many :office_enquiries, dependent: :destroy
end
