class CreateOfficeEnquiryWorkspaceTypes < ActiveRecord::Migration[8.0]
  def change
    create_table :office_enquiry_workspace_types do |t|
      t.references :office_enquiry, null: false, foreign_key: true
      t.references :workspace_type, null: false, foreign_key: true

      t.timestamps
    end
  end
end
