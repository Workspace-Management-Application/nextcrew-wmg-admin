class CreateDayPasses < ActiveRecord::Migration[8.0]
  def change
    create_table :day_passes do |t|
      t.integer :workspace_id
      t.string :name
      t.string :phone_number
      t.string :email
      t.integer :company_id
      t.date :pass_date
      t.text :purpose
      t.string :photo

      t.timestamps
    end
  end
end 