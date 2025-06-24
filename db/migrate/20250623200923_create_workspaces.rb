class CreateWorkspaces < ActiveRecord::Migration[8.0]
  def change
    create_table :workspaces do |t|
      t.string :name
      t.string :building_name
      t.text :address
      t.string :city
      t.string :pincode
      t.string :photo
      t.boolean :is_active

      t.timestamps
    end
  end
end
