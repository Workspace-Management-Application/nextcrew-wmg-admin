class Admin::DashboardController < Admin::BaseController
  def index
    # Get user's accessible workspaces
    user_workspaces = current_user.workspaces
    
    # Real dashboard metrics
    @total_workspaces = user_workspaces.count
    @total_rooms = Room.where(workspace: user_workspaces).count
    @todays_bookings = Booking.joins(room: :workspace)
                              .where(workspaces: { id: user_workspaces.pluck(:id) })
                              .where(start_time: Date.current.beginning_of_day..Date.current.end_of_day)
                              .count
    @day_passes_today = DayPass.where(workspace: user_workspaces)
                               .where(pass_date: Date.current)
                               .count
    
    # Get real 7-day booking data for chart
    @booking_chart_data = (6.days.ago.to_date..Date.current).map do |date|
      bookings_count = Booking.joins(room: :workspace)
                              .where(workspaces: { id: user_workspaces.pluck(:id) })
                              .where(start_time: date.beginning_of_day..date.end_of_day)
                              .count
      {
        date: date.strftime('%m/%d'),
        bookings: bookings_count
      }
    end
    
    # Additional useful metrics for dashboard
    @active_bookings = Booking.joins(room: :workspace)
                              .where(workspaces: { id: user_workspaces.pluck(:id) })
                              .where(status: 'confirmed')
                              .where(start_time: Time.current..)
                              .count
                              
    @total_visitor_entries = VisitorEntry.where(workspace: user_workspaces)
                                         .where(created_at: Date.current.beginning_of_day..Date.current.end_of_day)
                                         .count
  end
end
