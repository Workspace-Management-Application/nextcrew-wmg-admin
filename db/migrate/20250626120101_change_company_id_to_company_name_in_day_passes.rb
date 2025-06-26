class ChangeCompanyIdToCompanyNameInDayPasses < ActiveRecord::Migration[8.0]
  def change
    remove_column :day_passes, :company_id, :integer
    add_column :day_passes, :company_name, :string
  end
end
