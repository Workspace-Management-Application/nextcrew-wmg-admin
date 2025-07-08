class CreateRoomAmenities < ActiveRecord::Migration[8.0]
  def change
    create_table :room_amenities do |t|
      t.references :room, null: false, foreign_key: true
      t.references :amenity, null: false, foreign_key: true
      t.boolean :has_amenity

      t.timestamps
    end
  end
end
