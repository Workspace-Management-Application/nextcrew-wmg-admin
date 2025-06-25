class RemovePurposeFromBookings < ActiveRecord::Migration[8.0]
  def change
    remove_column :bookings, :purpose, :string
  end
end 