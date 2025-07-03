class Admin::CompaniesController < Admin::BaseController
  before_action :set_company, only: [:show, :edit, :update, :destroy]

  def index
    @search = params[:search]
    @companies = Company.includes(:users, :workspaces)
    
    # Search functionality
    if @search.present?
      @companies = @companies.where(
        "name ILIKE ? OR email ILIKE ? OR phone_number ILIKE ? OR address ILIKE ? OR status ILIKE ?",
        "%#{@search}%", "%#{@search}%", "%#{@search}%", "%#{@search}%", "%#{@search}%"
      )
    end
    
    # Filter by status if specified
    if params[:status].present?
      @companies = @companies.where(status: params[:status])
    end
    
    # Order by name
    @companies = @companies.order(:name)
    
    # Pagination
    @companies = @companies.page(params[:page]).per(10)
  end

  def show
    @company_users = @company.users
    @rooms = @company.rooms
    @available_rooms = @company.workspaces.first.rooms.where.not(id: @rooms.pluck(:id))

    @usage_analytics = calculate_usage_analytics(@company)
  end

  def new
    @company = Company.new
  end

  def create
    @company = Company.new(company_params)
    
    if @company.save
      redirect_to admin_companies_path, notice: 'Company was successfully created.'
    else
      render :new
    end
  end

  def edit
  end

  def update
    if @company.update(company_params)
      redirect_to admin_company_path(@company), notice: 'Company was successfully updated.'
    else
      render :edit
    end
  end

  def destroy
    @company.destroy
    redirect_to admin_companies_path, notice: 'Company was successfully deleted.'
  end

  def add_room
    @company = Company.find(params[:id])
    @room = Room.find(params[:room_id])
    @company.rooms << @room unless @company.rooms.include?(@room)
    redirect_to admin_company_path(@company), notice: "Room added."
  end

  def remove_room
    @company = Company.find(params[:id])
    @room = Room.find(params[:room_id])
    @company.rooms.delete(@room)
    redirect_to admin_company_path(@company), notice: "Room removed."
  end

  private

  def set_company
    @company = Company.find(params[:id])
  end

  def company_params
    params.require(:company).permit(:name, :email, :phone_number, :address, :status)
  end

  def calculate_usage_analytics(company)
    {
      total_users: company.users.count,
      total_bookings: company.users.joins(:bookings).count,
      this_month_bookings: company.users.joins(:bookings).where(bookings: { created_at: Date.current.beginning_of_month..Date.current.end_of_month }).count,
      active_users: company.users.joins(:bookings).where(bookings: { created_at: 30.days.ago..Date.current }).distinct.count
    }
  end
end
