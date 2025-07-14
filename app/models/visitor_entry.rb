class VisitorEntry < ApplicationRecord
  belongs_to :workspace

  # Active Storage attachment for visitor photos (ID photos, etc.)
  has_one_attached :photo

  validates :name, :person_to_visit_name, :email, :phone_number, :purpose, presence: true
  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP, message: "invalid email format" }
  validates :phone_number, format: { with: /\A[1-9][0-9]{9}\z/, message: "must be 10 digits and not start with zero" }
end
