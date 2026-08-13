class Api::BookingsController < Api::BaseController
  before_action :set_workspace
  before_action :set_booking, only: [ :show, :update ]

  # GET /api/bookings
  def index
    bookings = Booking.confirmed.where(room_id: @workspace.rooms.select(:id))
    render_success(bookings)
  end

  # GET /api/bookings/:id
  def show
    if @booking
      render_success(@booking)
    else
      render_error("Booking not found", :not_found)
    end
  end

  # POST /api/bookings
  def create
    return render_booking_access_error unless current_user.can_book_for_company?

    company = Company.find_by(id: booking_params[:company_id])
    unless company
      return render_error("Company not found", :unprocessable_entity)
    end

    @booking = Booking.new(booking_params)
    @booking.company = company
    @booking.acting_user = current_user

    unless @workspace.rooms.exists?(id: @booking.room_id)
      return render_error("Room does not belong to this workspace", :unprocessable_entity)
    end

    if @booking.save
      if @booking.company.email_notifications_enabled?
        begin
          BookingMailer.booking_confirmation(@booking).deliver_later
          Rails.logger.info "Booking confirmation email queued for delivery to #{@booking.company.notification_email}"
        rescue Net::SMTPError, Net::OpenTimeoutError => e
          Rails.logger.error "SMTP error queueing booking confirmation email: #{e.message}"
          Rails.logger.error e.backtrace.join("\n")
        rescue StandardError => e
          Rails.logger.error "Failed to queue booking confirmation email: #{e.message}"
          Rails.logger.error e.backtrace.join("\n")
        end
      else
        Rails.logger.info "Booking confirmation email skipped because company email notifications are disabled for #{@booking.company.id}"
      end
      render_success(@booking, "Booking created successfully", :created)
    else
      render_error(@booking.all_validation_errors)
    end
  end

  # PATCH/PUT /api/bookings/:id
  def update
    if @booking
      return render_booking_access_error unless current_user.can_book_for_company?

      if booking_params[:room_id] && !@workspace.rooms.exists?(id: booking_params[:room_id])
        return render_error("Room does not belong to this workspace", :unprocessable_entity)
      end
      @booking.acting_user = current_user
      if @booking.update(booking_params)
        render_success(@booking, "Booking updated successfully")
      else
        render_error(@booking.all_validation_errors)
      end
    else
      render_error("Booking not found", :not_found)
    end
  end

  private

  def set_workspace
    @workspace = Workspace.find_by(id: params[:workspace_id])
    render_error("Workspace not found", :not_found) unless @workspace
  end

  def set_booking
    @booking = Booking.confirmed.where(room_id: @workspace.rooms.select(:id)).find_by(id: params[:id])
  end

  def booking_params
    params.require(:booking).permit(:company_id, :booker_name, :phone_number, :room_id, :start_time, :end_time)
  end

  def render_booking_access_error
    render_error("This user is not allowed to create or update bookings", :forbidden)
  end
end
