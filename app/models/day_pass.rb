class DayPass < ApplicationRecord
  belongs_to :workspace

  # Active Storage attachment for day pass photos (ID photos, etc.)
  has_one_attached :photo

  validates :name, :email, :phone_number, :pass_date, :purpose, presence: true
  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP, message: "invalid email format" }
  validates :phone_number, format: { with: /\A(\+?\d{1,3}[- ]?)?\(?\d{1,4}?\)?[- ]?\d{1,4}[- ]?\d{1,4}\z/, message: "invalid phone number format" }
end
