class OfficeEnquiryWorkspaceType < ApplicationRecord
  belongs_to :office_enquiry
  belongs_to :workspace_type
 
  validates :office_enquiry_id, uniqueness: { scope: :workspace_type_id }
end 