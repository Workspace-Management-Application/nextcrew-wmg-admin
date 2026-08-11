class AddCompanyUserTypeToUsers < ActiveRecord::Migration[8.0]
  def up
    add_column :users, :company_user_type, :string, default: "booking_user"

    User.reset_column_information
    User.where(company_user_type: nil).update_all(company_user_type: "booking_user")
  end

  def down
    remove_column :users, :company_user_type
  end
end
