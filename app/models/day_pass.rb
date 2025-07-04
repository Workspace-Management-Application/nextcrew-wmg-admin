class DayPass < ApplicationRecord
  belongs_to :workspace

  # Active Storage attachments for day pass photos
  has_one_attached :photo
  has_one_attached :id_proof

  validates :name, :email, :phone_number, :pass_date, presence: true
  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP, message: "invalid email format" }
  validates :phone_number, format: { with: /\A(\+?\d{1,3}[- ]?)?\(?\d{1,4}?\)?[- ]?\d{1,4}[- ]?\d{1,4}\z/, message: "invalid phone number format" }
end
