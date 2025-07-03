class AddNoOfSeatsToOfficeEnquiries < ActiveRecord::Migration[8.0]
  def change
    add_column :office_enquiries, :no_of_seats, :integer
  end
end
