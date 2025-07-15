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

  # Constants for shift types
  SHIFT_TYPES = ['Day Shift', '24x7 Shift', 'Night Shift Only'].freeze

  validates :name, :email, :phone_number, :address, :cabin_number, :no_of_employee, :meeting_time_limit_per_month, :no_of_meeting_per_day, :meeting_time_limit_per_day, :minimum_minutes_meeting_limit, :max_minutes_meeting_limit, presence: true
  validates :phone_number, uniqueness: true
  validates :email, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP, message: "invalid email format" }
  # Phone number must be exactly 10 digits and not start with zero
  validates :phone_number, format: { with: /\A[1-9][0-9]{9}\z/, message: "must be 10 digits and not start with zero" }
  validates :no_of_employee, :meeting_time_limit_per_month, :no_of_meeting_per_day, :meeting_time_limit_per_day, :minimum_minutes_meeting_limit, :max_minutes_meeting_limit, numericality: { greater_than: 0, only_integer: true }
  validates :max_minutes_meeting_limit, numericality: { greater_than: :minimum_minutes_meeting_limit, message: "must be greater than minimum minutes meeting limit" }
  validates :meeting_time_limit_per_day, numericality: { less_than_or_equal_to: :meeting_time_limit_per_month, message: "daily limit cannot exceed monthly limit" }
  
  # Validations for new fields
  validates :centre_address, :commencement_date, :lock_in_period, :no_of_seats, :floor_no, :shift_type, :agreement_date, :company_poc_contact, :company_email_address, :lease_expiry_date, :cost_per_seat, presence: true
  validates :company_email_address, format: { with: URI::MailTo::EMAIL_REGEXP, message: "invalid email format" }
  validates :lock_in_period, :no_of_seats, :cost_per_seat, numericality: { greater_than: 0, only_integer: true }
  validates :shift_type, inclusion: { in: SHIFT_TYPES, message: "must be one of: #{SHIFT_TYPES.join(', ')}" }
  validates :commencement_date, :agreement_date, :lease_expiry_date, presence: true
  validate :lease_expiry_date_after_commencement_date
  validate :agreement_date_before_lease_expiry_date

  private

  def lease_expiry_date_after_commencement_date
    return unless lease_expiry_date.present? && commencement_date.present?
    
    if lease_expiry_date <= commencement_date
      errors.add(:lease_expiry_date, "must be after commencement date")
    end
  end

  def agreement_date_before_lease_expiry_date
    return unless agreement_date.present? && lease_expiry_date.present?
    
    if agreement_date >= lease_expiry_date
      errors.add(:agreement_date, "must be before lease expiry date")
    end
  end
end
