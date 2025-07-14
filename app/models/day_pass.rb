class DayPass < ApplicationRecord
  belongs_to :workspace

  # Active Storage attachments for day pass photos
  has_one_attached :photo
  has_one_attached :id_proof

  validates :name, :email, :phone_number, :pass_date, presence: true
  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP, message: "invalid email format" }
  validates :phone_number, format: { with: /\A[1-9][0-9]{9}\z/, message: "must be 10 digits and not start with zero" }
end
