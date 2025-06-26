class Admin::DashboardController < Admin::BaseController
  def index
    # Mock data for testing
    @total_workspaces = 2
    @total_rooms = 6
    @todays_bookings = 0
    @day_passes_today = 0
    
    # Get 7-day booking data for chart
    @booking_chart_data = (6.days.ago.to_date..Date.current).map do |date|
      {
        date: date.strftime('%m/%d'),
        bookings: rand(0..5) # Random data for testing
      }
    end
  end
end
