class CreateVisitorEntries < ActiveRecord::Migration[8.0]
  def change
    create_table :visitor_entries do |t|
      t.string :name
      t.integer :workspace_id
      t.string :person_to_visit_name
      t.string :phone_number
      t.string :email
      t.string :purpose
      t.string :image

      t.timestamps
    end
  end
end 