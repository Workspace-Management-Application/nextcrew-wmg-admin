class RemovePurposeFromBookings < ActiveRecord::Migration[8.0]
  def change
    remove_column :bookings, :purpose, :string
    remove_column :office_enquiries, :visitor_name, :string
    rename_column :visitor_entries, :image, :photo
    remove_column :bookings, :booker_name, :string
    add_column :users, :phone_number, :string
  end
end 