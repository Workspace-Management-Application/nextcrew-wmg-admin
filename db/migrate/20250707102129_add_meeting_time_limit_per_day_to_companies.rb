class AddMeetingTimeLimitPerDayToCompanies < ActiveRecord::Migration[8.0]
  def change
    add_column :companies, :meeting_time_limit_per_day, :integer, default: 480, null: false
  end
end
