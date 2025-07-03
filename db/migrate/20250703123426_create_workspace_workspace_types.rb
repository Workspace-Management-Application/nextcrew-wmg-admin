class CreateWorkspaceWorkspaceTypes < ActiveRecord::Migration[8.0]
  def change
    create_table :workspace_workspace_types do |t|
      t.references :workspace, null: false, foreign_key: true
      t.references :workspace_type, null: false, foreign_key: true

      t.timestamps
    end
  end
end
