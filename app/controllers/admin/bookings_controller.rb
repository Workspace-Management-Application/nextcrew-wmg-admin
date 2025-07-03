class Admin::BookingsController < Admin::BaseController
  before_action :set_booking, only: [:show, :edit, :update, :destroy]

  def index
    @search = params[:search]
    @bookings = Booking.includes(:user, :room, room: :workspace)
    
    # Search functionality
    if @search.present?
      @bookings = @bookings.joins(:user, :room).where(
        "users.name ILIKE ? OR users.email ILIKE ? OR rooms.name ILIKE ? OR bookings.phone_number ILIKE ?",
        "%#{@search}%", "%#{@search}%", "%#{@search}%", "%#{@search}%"
      )
    end
    
    # Filter by date if specified
    if params[:date].present?
      @bookings = @bookings.where('DATE(start_time) = ?', Date.parse(params[:date]))
    end
    
    # Filter by workspace if specified
    if params[:workspace_id].present?
      @bookings = @bookings.joins(:room).where(rooms: { workspace_id: params[:workspace_id] })
    end
    
    # Filter by status if specified
    if params[:status].present?
      @bookings = @bookings.where(status: params[:status])
    end
    
    # Order by start time descending
    @bookings = @bookings.order(start_time: :desc)
    
    # Pagination
    @bookings = @bookings.page(params[:page]).per(15)
  end

  def show
  end

  def new
    @booking = Booking.new
    @workspaces = Workspace.all
    @rooms = Room.all
    @users = User.all
  end

  def create
    @booking = Booking.new(booking_params)
    if @booking.save
      # Send booking confirmation email
      begin
        BookingMailer.booking_confirmation(@booking).deliver_now
      rescue => e
        Rails.logger.error "Failed to send booking confirmation email: #{e.message}"
        # Don't fail the booking creation if email fails
      end
      
      redirect_to admin_bookings_path, notice: 'Booking was successfully created.'
    else
      @workspaces = Workspace.all
      @rooms = Room.all
      @users = User.all
      render :new
    end
  end

  def edit
    @workspaces = Workspace.all
    @rooms = Room.all
    @users = User.all
  end

  def update
    if @booking.update(booking_params)
      redirect_to admin_booking_path(@booking), notice: 'Booking was successfully updated.'
    else
      @workspaces = Workspace.all
      @rooms = Room.all
      @users = User.all
      render :edit
    end
  end

  def destroy
    @booking.destroy
    redirect_to admin_bookings_path, notice: 'Booking was successfully cancelled.'
  end

  private

  def set_booking
    @booking = Booking.find(params[:id])
  end

  def booking_params
    params.require(:booking).permit(:user_id, :room_id, :phone_number, :start_time, :end_time)
  end
end
