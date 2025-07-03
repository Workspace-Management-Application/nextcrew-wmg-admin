class Api::BookingsController < Api::BaseController
  before_action :set_workspace
  before_action :set_booking, only: [:show, :update, :destroy]

  # GET /api/bookings
  def index
    bookings = Booking.where(room_id: @workspace.rooms.select(:id))
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
    unless @workspace.rooms.exists?(id: booking.room_id)
      return render_error('Room does not belong to this workspace', :unprocessable_entity)
    end
    if booking.save
      # Send booking confirmation email
      begin
        BookingMailer.booking_confirmation(booking).deliver_now
      rescue => e
        Rails.logger.error "Failed to send booking confirmation email: #{e.message}"
        # Don't fail the booking creation if email fails
      end
      
      render_success(booking, 'Booking created successfully', :created)
    else
      render_error(booking.errors.full_messages.join(', '))
    end
  end

  # PATCH/PUT /api/bookings/:id
  def update
    if @booking
      if booking_params[:room_id] && !@workspace.rooms.exists?(id: booking_params[:room_id])
        return render_error('Room does not belong to this workspace', :unprocessable_entity)
      end
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

  def set_workspace
    @workspace = Workspace.find_by(id: params[:workspace_id])
    render_error('Workspace not found', :not_found) unless @workspace
  end

  def set_booking
    @booking = Booking.where(room_id: @workspace.rooms.select(:id)).find_by(id: params[:id])
  end

  def booking_params
    params.require(:booking).permit(:booker_name, :phone_number, :room_id, :start_time, :end_time, :status)
  end
end
