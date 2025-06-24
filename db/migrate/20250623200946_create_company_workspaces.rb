class CreateCompanyWorkspaces < ActiveRecord::Migration[8.0]
  def change
    create_table :company_workspaces do |t|
      t.integer :company_id
      t.integer :workspace_id

      t.timestamps
    end
  end
end
