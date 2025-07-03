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
    
    # Get available rooms from all workspaces that the company is associated with
    if @company.workspaces.any?
      workspace_room_ids = @company.workspaces.joins(:rooms).pluck('rooms.id')
      @available_rooms = Room.where(id: workspace_room_ids).where.not(id: @rooms.pluck(:id))
    else
      @available_rooms = []
    end
    
    # Get available users (role 'user' and not assigned to any company)
    @available_users = User.where(role: ['user', 'floor_user'])
                          .left_joins(:company_users)
                          .where(company_users: { id: nil })

    @usage_analytics = calculate_usage_analytics(@company)
  end

  def new
    @company = Company.new
  end

  def create
    @company = Company.new(company_params)
    # Ensure new companies have pending status by default
    @company.status = 'pending' unless current_user.super_admin?
    
    if @company.save
      redirect_to admin_companies_path, notice: 'Company was successfully created.'
    else
      render :new
    end
  end

  def edit
  end

  def update
    # Handle status authorization
    if company_params[:status].present?
      unless can_change_company_status?(@company, company_params[:status])
        redirect_to edit_admin_company_path(@company), alert: 'You are not authorized to make this status change.'
        return
      end
    end
    
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

  def add_user
    @company = Company.find(params[:id])
    @user = User.find(params[:user_id])
    
    unless @company.users.include?(@user)
      @company.users << @user
      redirect_to admin_company_path(@company), notice: "User added to company successfully."
    else
      redirect_to admin_company_path(@company), alert: "User is already assigned to this company."
    end
  end

  def remove_user
    @company = Company.find(params[:id])
    @user = User.find(params[:user_id])
    @company.users.delete(@user)
    redirect_to admin_company_path(@company), notice: "User removed from company."
  end

  def quick_status_change
    @company = Company.find(params[:id])
    
    if current_user.super_admin? && @company.status != 'active'
      # Super admin can activate any non-active company
      @company.update(status: 'active')
      redirect_to admin_companies_path, notice: "Company '#{@company.name}' has been activated successfully."
    elsif current_user.admin? && @company.status == 'active'
      # Admin can only deactivate active companies
      @company.update(status: 'inactive')
      redirect_to admin_companies_path, notice: "Company '#{@company.name}' has been deactivated successfully."
    else
      redirect_to admin_companies_path, alert: "You are not authorized to make this status change."
    end
  end

  private

  def set_company
    @company = Company.find(params[:id])
  end

  def company_params
    permitted_params = [:name, :email, :phone_number, :address]
    
    # Only allow status parameter for super_admin or admin with restrictions
    if current_user.super_admin?
      permitted_params << :status
    elsif current_user.admin?
      # Admin can only change status if it's from active to inactive
      if params[:company][:status].present? && @company&.status == 'active' && params[:company][:status] == 'inactive'
        permitted_params << :status
      end
    end
    
    params.require(:company).permit(permitted_params)
  end

  def calculate_usage_analytics(company)
    {
      total_users: company.users.count,
      total_bookings: company.users.joins(:bookings).count,
      this_month_bookings: company.users.joins(:bookings).where(bookings: { created_at: Date.current.beginning_of_month..Date.current.end_of_month }).count,
      active_users: company.users.joins(:bookings).where(bookings: { created_at: 30.days.ago..Date.current }).distinct.count
    }
  end

  def can_change_company_status?(company, new_status)
    return true if current_user.super_admin?
    
    if current_user.admin?
      # Admin can only change from active to inactive
      return company.status == 'active' && new_status == 'inactive'
    end
    
    false
  end
end
