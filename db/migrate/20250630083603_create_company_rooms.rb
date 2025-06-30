class CreateCompanyRooms < ActiveRecord::Migration[8.0]
  def change
    create_table :company_rooms do |t|
      t.references :company, null: false, foreign_key: true
      t.references :room, null: false, foreign_key: true

      t.timestamps
    end
  end
end
