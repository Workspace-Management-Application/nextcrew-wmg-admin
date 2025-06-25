class Company < ApplicationRecord
  has_many :company_users
  has_many :users, through: :company_users
  has_many :company_workspaces
  has_many :workspaces, through: :company_workspaces
  has_many :day_passes

  enum :status, { active: 'active', inactive: 'inactive', pending: 'pending', approved: 'approved' }, default: :pending

  validates :name, :email, :phone_number, :address, presence: true
  validates :phone_number, uniqueness: true
  validates :email, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP, message: "invalid email format" }
  validates :phone_number, format: { with: /\A(\+?\d{1,3}[- ]?)?\(?\d{1,4}?\)?[- ]?\d{1,4}[- ]?\d{1,4}\z/, message: "invalid phone number format" }
end
