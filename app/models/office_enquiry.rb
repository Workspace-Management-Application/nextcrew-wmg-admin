class OfficeEnquiry < ApplicationRecord
  belongs_to :workspace

  validates :enquirer_name, :email, :phone_number, :requirement, :company_name, presence: true
end
