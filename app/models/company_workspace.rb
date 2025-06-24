class CompanyWorkspace < ApplicationRecord
  belongs_to :company
  belongs_to :workspace
end
