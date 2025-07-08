class Company < ApplicationRecord
  has_many :company_users
  has_many :users, through: :company_users
  has_many :company_workspaces
  has_many :workspaces, through: :company_workspaces
  has_many :day_passes
  has_many :company_rooms, dependent: :destroy
  has_many :rooms, through: :company_rooms
  has_many :bookings

  enum :status, { active: 'active', inactive: 'inactive' }, default: :active

  validates :name, :email, :phone_number, :address, :cabin_number, :no_of_employee, :meeting_time_limit_per_month, :no_of_meeting_per_day, :meeting_time_limit_per_day, :minimum_minutes_meeting_limit, :max_minutes_meeting_limit, presence: true
  validates :phone_number, uniqueness: true
  validates :email, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP, message: "invalid email format" }
  validates :phone_number, format: { with: /\A(\+?\d{1,3}[- ]?)?\(?\d{1,4}?\)?[- ]?\d{1,4}[- ]?\d{1,4}\z/, message: "invalid phone number format" }
  validates :no_of_employee, :meeting_time_limit_per_month, :no_of_meeting_per_day, :meeting_time_limit_per_day, :minimum_minutes_meeting_limit, :max_minutes_meeting_limit, numericality: { greater_than: 0, only_integer: true }
  validates :max_minutes_meeting_limit, numericality: { greater_than: :minimum_minutes_meeting_limit, message: "must be greater than minimum minutes meeting limit" }
  validates :meeting_time_limit_per_day, numericality: { less_than_or_equal_to: :meeting_time_limit_per_month, message: "daily limit cannot exceed monthly limit" }
end
