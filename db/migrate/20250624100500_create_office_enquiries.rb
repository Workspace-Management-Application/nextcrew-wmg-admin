class CreateOfficeEnquiries < ActiveRecord::Migration[8.0]
  def change
    create_table :office_enquiries do |t|
      t.integer :workspace_id
      t.string :enquirer_name
      t.string :visitor_name
      t.string :phone_number
      t.string :email
      t.string :requirement
      t.string :company_name

      t.timestamps
    end
  end
end 