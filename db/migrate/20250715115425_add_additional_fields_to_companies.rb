class AddAdditionalFieldsToCompanies < ActiveRecord::Migration[8.0]
  def change
    add_column :companies, :centre_address, :string
    add_column :companies, :commencement_date, :date
    add_column :companies, :lock_in_period, :integer
    add_column :companies, :no_of_seats, :integer
    add_column :companies, :floor_no, :string
    add_column :companies, :shift_type, :string
    add_column :companies, :agreement_date, :date
    add_column :companies, :company_poc_contact, :string
    add_column :companies, :company_email_address, :string
    add_column :companies, :name_board_charges, :boolean
    add_column :companies, :lease_expiry_date, :date
    add_column :companies, :cost_per_seat, :integer
  end
end
