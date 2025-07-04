class RemovePurposeFromDayPasses < ActiveRecord::Migration[8.0]
  def change
    remove_column :day_passes, :purpose, :string
  end
end
