class RemoveAmenitiesFromRooms < ActiveRecord::Migration[8.0]
  def change
    remove_column :rooms, :whiteboard, :boolean
    remove_column :rooms, :projector, :boolean
    remove_column :rooms, :tv, :boolean
  end
end
