class CreateRooms < ActiveRecord::Migration[8.0]
  def change
    create_table :rooms do |t|
      t.string :name
      t.string :category
      t.references :workspace, null: false, foreign_key: true
      t.integer :capacity
      t.boolean :whiteboard, default: false
      t.boolean :projector, default: false
      t.boolean :is_available, default: true

      t.timestamps
    end
  end
end 