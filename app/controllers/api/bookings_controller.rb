class Api::BookingsController < Api::BaseController
  before_action :authenticate_user!
  before_action :set_booking, only: [:show, :update, :destroy]

  # GET /api/bookings
  def index
    bookings = Booking.all
    render_success(bookings)
  end

  # GET /api/bookings/:id
  def show
    if @booking
      render_success(@booking)
    else
      render_error('Booking not found', :not_found)
    end
  end

  # POST /api/bookings
  def create
    booking = current_user.bookings.new(booking_params)
    if booking.save
      render_success(booking, 'Booking created successfully', :created)
    else
      render_error(booking.errors.full_messages.join(', '))
    end
  end

  # PATCH/PUT /api/bookings/:id
  def update
    if @booking
      if @booking.update(booking_params)
        render_success(@booking, 'Booking updated successfully')
      else
        render_error(@booking.errors.full_messages.join(', '))
      end
    else
      render_error('Booking not found', :not_found)
    end
  end

  # DELETE /api/bookings/:id
  def destroy
    if @booking
      @booking.destroy
      render_success({}, 'Booking deleted successfully')
    else
      render_error('Booking not found', :not_found)
    end
  end

  private

  def set_booking
    @booking = Booking.find_by(id: params[:id])
  end

  def booking_params
    params.require(:booking).permit(:booker_name, :phone_number, :room_id, :start_time, :end_time, :status)
  end
end
