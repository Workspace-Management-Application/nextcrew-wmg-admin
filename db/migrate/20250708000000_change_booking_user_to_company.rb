class ChangeBookingUserToCompany < ActiveRecord::Migration[7.0]
  def change
    add_reference :bookings, :company, foreign_key: true
    remove_column :bookings, :user_id
  end
end 