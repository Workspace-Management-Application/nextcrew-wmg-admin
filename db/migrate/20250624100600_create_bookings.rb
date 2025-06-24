 class CreateBookings < ActiveRecord::Migration[8.0]
  def change
    create_table :bookings do |t|
      t.string :booker_name
      t.string :phone_number
      t.integer :user_id
      t.integer :room_id
      t.datetime :start_time
      t.datetime :end_time
      t.string :purpose
      t.string :status

      t.timestamps
    end
  end
end
