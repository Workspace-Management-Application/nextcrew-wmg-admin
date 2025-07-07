class RemoveDefaultFromMeetingTimeLimitPerDay < ActiveRecord::Migration[8.0]
  def change
    change_column_default :companies, :meeting_time_limit_per_day, from: 480, to: nil
  end
end
