class BookingMailer < ApplicationMailer
  default from: "bookings@nextcoworks.com"

  def booking_confirmation(booking)
    @booking = booking
    @company = booking.company
    @room = booking.room
    @workspace = booking.room.workspace

    mail(
      to: @company.email,
      subject: "Booking Confirmation - #{@room.name} at #{@workspace.name}"
    )
  end

  def monthly_limit_exceeded_notification(booking)
    @booking = booking
    @company = booking.company
    @room = booking.room
    @workspace = booking.room.workspace

    # Calculate company's monthly usage
    booking_month = @booking.start_time.beginning_of_month
    intervals = Booking.joins(:company)
      .where(company: @company)
      .where("start_time >= ? AND start_time < ?", booking_month, booking_month.next_month)
      .pluck(Arel.sql("EXTRACT(EPOCH FROM (end_time - start_time))"))

    # Convert seconds to minutes and sum the intervals
    @total_monthly_minutes = intervals.map { |seconds| seconds.to_f / 60 }.sum
    @monthly_limit = @company.meeting_time_limit_per_month
    @exceeded_minutes = [ @total_monthly_minutes - @monthly_limit, 0 ].max

    # Send to company email
    mail(
      to: @company.email,
      subject: "Monthly Meeting Limit Exceeded - #{@company.name}"
    )
  end

  def daily_limit_exceeded_notification(booking)
    @booking = booking
    @company = booking.company
    @room = booking.room
    @workspace = booking.room.workspace

    # Calculate company's daily usage
    booking_date = @booking.start_time.to_date
    intervals = Booking.joins(:company)
      .where(company: @company)
      .where("DATE(start_time) = ?", booking_date)
      .pluck(Arel.sql("EXTRACT(EPOCH FROM (end_time - start_time))"))

    # Convert seconds to minutes and sum the intervals
    @total_daily_minutes = intervals.map { |seconds| seconds.to_f / 60 }.sum
    @daily_limit = @company.meeting_time_limit_per_day
    @exceeded_minutes = [ @total_daily_minutes - @daily_limit, 0 ].max

    # Send to company email
    mail(
      to: @company.email,
      subject: "Daily Meeting Limit Exceeded - #{@company.name}"
    )
  end
end
