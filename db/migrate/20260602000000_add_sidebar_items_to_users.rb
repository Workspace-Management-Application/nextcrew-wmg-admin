class AddSidebarItemsToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :sidebar_items, :jsonb
  end
end
