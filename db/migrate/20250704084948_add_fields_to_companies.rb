class AddFieldsToCompanies < ActiveRecord::Migration[8.0]
  def change
    add_column :companies, :cabin_number, :string
    add_column :companies, :no_of_employee, :integer
    add_column :companies, :meeting_time_limit_per_month, :integer
    add_column :companies, :no_of_meeting_per_day, :integer
    add_column :companies, :minimum_minutes_meeting_limit, :integer
    add_column :companies, :max_minutes_meeting_limit, :integer
  end
end
