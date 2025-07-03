class RemoveRequirementFromOfficeEnquiries < ActiveRecord::Migration[8.0]
  def change
    remove_column :office_enquiries, :requirement, :string
  end
end
