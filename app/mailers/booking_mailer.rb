class BookingMailer < ApplicationMailer
  default from: 'bookings@nextcoworks.com'

  def booking_confirmation(booking)
    @booking = booking
    @user = booking.user
    @room = booking.room
    @workspace = booking.room.workspace
    
    mail(
      to: @user.email,
      subject: "Booking Confirmation - #{@room.name} at #{@workspace.name}"
    )
  end
end 