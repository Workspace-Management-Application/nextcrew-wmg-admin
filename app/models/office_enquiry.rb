class OfficeEnquiry < ApplicationRecord
  belongs_to :workspace
  has_many :office_enquiry_workspace_types, dependent: :destroy
  has_many :workspace_types, through: :office_enquiry_workspace_types

  validates :enquirer_name, :email, :phone_number, :company_name, presence: true
  validates :no_of_seats, presence: true, numericality: { only_integer: true, greater_than: 0 }
  validates :phone_number, format: { with: /\A[1-9][0-9]{9}\z/, message: "must be 10 digits and not start with zero" }
end
