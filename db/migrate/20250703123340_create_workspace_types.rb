class CreateWorkspaceTypes < ActiveRecord::Migration[8.0]
  def change
    create_table :workspace_types do |t|
      t.string :name, null: false

      t.timestamps
    end
    
    add_index :workspace_types, :name, unique: true
  end
end
