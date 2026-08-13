class AddEmailNotificationsEnabledToCompanies < ActiveRecord::Migration[8.0]
  def change
    add_column :companies, :email_notifications_enabled, :boolean, default: true, null: false
  end
end
