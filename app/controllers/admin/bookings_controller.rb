class Admin::BookingsController < Admin::BaseController
  before_action :set_booking, only: [:show, :edit, :update, :destroy]

  def index
    @search = params[:search]
    workspace_ids = current_user.workspaces.pluck(:id)
    @bookings = Booking.joins(room: :workspace)
                     .where(rooms: { workspace_id: workspace_ids })
                     .includes(:company, :room, room: :workspace).order(created_at: :desc)
    
    # Search functionality
    if @search.present?
      @bookings = @bookings.joins(:company, :room).where(
        "companies.name ILIKE ? OR companies.email ILIKE ? OR rooms.name ILIKE ? OR bookings.phone_number ILIKE ?",
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
    @bookings = @bookings.order(start_time: :asc)
    
    # Pagination
    @bookings = @bookings.page(params[:page]).per(15)
  end

  def show
  end

  def new
    @booking = Booking.new
    @companies = Company.all
    @rooms = [] # Start with empty rooms, will be populated via JavaScript
  end

  def create
    @booking = Booking.new(booking_params)
    @booking.acting_user = current_user
    if @booking.save
      # Send booking confirmation email
      begin
        BookingMailer.booking_confirmation(@booking).deliver_now
      rescue => e
        Rails.logger.error "Failed to send booking confirmation email: #{e.message}"
        # Don't fail the booking creation if email fails
      end
      
      # Note: Monthly limit exceeded notification is automatically sent by the model validation
      # if the company exceeds their monthly limit
      
      redirect_to admin_bookings_path, notice: 'Booking was successfully created.'
    else
      @companies = Company.all
      @rooms = Room.all
      render :new
    end
  end

  def edit
    unless @booking.editable?
      redirect_to admin_booking_path(@booking), alert: 'Cannot edit completed bookings.'
      return
    end
    
    @companies = Company.all
    @rooms = @booking.company.rooms.includes(:workspace) # Load rooms for the current company
  end

  def update
    unless @booking.editable?
      redirect_to admin_booking_path(@booking), alert: 'Cannot update completed bookings.'
      return
    end
    
    @booking.acting_user = current_user
    if @booking.update(booking_params)
      redirect_to admin_booking_path(@booking), notice: 'Booking was successfully updated.'
    else
      @companies = Company.all
      @rooms = Room.all
      render :edit
    end
  end

  def destroy
    @booking.destroy
    redirect_to admin_bookings_path, notice: 'Booking was successfully cancelled.'
  end

  def company_rooms
    company = Company.find(params[:company_id])
    rooms = company.rooms.includes(:workspace).map do |room|
      {
        id: room.id,
        name: "#{room.name} - #{room.workspace.name}"
      }
    end
    render json: rooms
  end

  private

  def set_booking
    @booking = Booking.find(params[:id])
  end

  def booking_params
    params.require(:booking).permit(:company_id, :room_id, :phone_number, :start_time, :end_time)
  end
end
