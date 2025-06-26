class Admin::BookingsController < Admin::BaseController
  before_action :set_booking, only: [:show, :edit, :update, :destroy]

  def index
    @bookings = Booking.includes(:user, :room).order(created_at: :desc)
    @bookings = @bookings.where('DATE(start_time) = ?', Date.parse(params[:date])) if params[:date].present?
    @bookings = @bookings.joins(:room).where(rooms: { workspace_id: params[:workspace_id] }) if params[:workspace_id].present?
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
    params.require(:booking).permit(:user_id, :room_id, :start_time, :end_time, :purpose)
  end
end
