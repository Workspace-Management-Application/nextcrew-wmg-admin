class AddTvToRooms < ActiveRecord::Migration[8.0]
  def change
    add_column :rooms, :tv, :boolean, default: false
  end
end
