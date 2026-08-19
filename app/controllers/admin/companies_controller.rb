class Admin::CompaniesController < Admin::BaseController
  before_action :set_company, only: [:show, :edit, :update, :destroy]

  def index
    @search = params[:search]
    workspace_ids = current_user.workspaces.pluck(:id)
    @companies = Company.joins(:workspaces)
                        .where(workspaces: { id: workspace_ids })
                        .distinct
                        .includes(:users, :workspaces).order(created_at: :desc)
    
    # Search functionality
    if @search.present?
      search_term = "%#{@search}%"
      @companies = @companies.where(
        "companies.name ILIKE ? OR companies.email ILIKE ? OR companies.phone_number ILIKE ? OR companies.address ILIKE ? OR companies.status ILIKE ? OR companies.cabin_number ILIKE ? OR companies.centre_address ILIKE ? OR companies.company_poc_contact ILIKE ? OR companies.company_email_address ILIKE ?",
        search_term, search_term, search_term, search_term, search_term, search_term, search_term, search_term, search_term
      )
    end
    
    # Filter by status if specified
    if params[:status].present?
      @companies = @companies.where(companies: { status: params[:status] })
    end
    
    # Order by name
    @companies = @companies.order("companies.name")
    # Pagination
    @companies = @companies.page(params[:page]).per(10)
  end

  def show
    @company_booking_users = @company.users.booking_user
    @company_employees = @company.users.employee
    @rooms = @company.rooms
    
    # Get available rooms from all workspaces that the company is associated with
    if @company.workspaces.any?
      workspace_room_ids = @company.workspaces.joins(:rooms).pluck('rooms.id')
      @available_rooms = Room.where(id: workspace_room_ids).where.not(id: @rooms.pluck(:id))
    else
      @available_rooms = []
    end
    
    # Get available users (role 'user' and not assigned to any company)
    @available_users = User.where(role: ['user'])
                          .left_joins(:company_users)
                          .where(company_users: { id: nil })

    @usage_analytics = calculate_usage_analytics(@company)
  end

  def new
    @company = Company.new
    @workspaces = current_user.workspaces.completed.order(:name)
  end

  def create
    @company = Company.new(company_params)
    # All new companies default to active status
    @company.status = 'active'
    
    if @company.save
      # Assign workspace if selected
      if params[:company][:workspace_id].present?
        @company.company_workspaces.create(workspace_id: params[:company][:workspace_id])
      end
      
      # Assign rooms if selected
      if params[:company][:room_ids].present?
        params[:company][:room_ids].each do |room_id|
          @company.company_rooms.create(room_id: room_id) if room_id.present?
        end
      end
      
      redirect_to admin_companies_path, notice: 'Company was successfully created.'
    else
      @workspaces = Workspace.order(:name)
      render :new
    end
  end

  def edit
    @workspaces = current_user.workspaces.completed.order(:name)
    @rooms = Room.joins(:workspace).where(workspaces: { id: @company.workspaces.pluck(:id) }).order(:name)
  end

  def update
    # Only super_admin can change status
    if company_params[:status].present? && !current_user.super_admin?
      redirect_to edit_admin_company_path(@company), alert: 'Only Super Admin can change company status.'
      return
    end
    
    if @company.update(company_params)
      # Update workspace assignment
      if params[:company][:workspace_id].present?
        @company.company_workspaces.destroy_all
        @company.company_workspaces.create(workspace_id: params[:company][:workspace_id])
      else
        @company.company_workspaces.destroy_all
      end
      
      # Update room assignments
      @company.company_rooms.destroy_all
      if params[:company][:room_ids].present?
        params[:company][:room_ids].each do |room_id|
          @company.company_rooms.create(room_id: room_id) if room_id.present?
        end
      end
      
      redirect_to admin_company_path(@company), notice: 'Company was successfully updated.'
    else
      @workspaces = Workspace.order(:name)
      @rooms = Room.joins(:workspace).where(workspaces: { id: @company.workspaces.pluck(:id) }).order(:name)
      render :edit
    end
  end

  def destroy
    @company.destroy
    redirect_to admin_companies_path, notice: 'Company was successfully deleted.'
  end

  # API endpoint to get rooms for a specific workspace
  def rooms_for_workspace
    workspace_id = params[:workspace_id]
    rooms = Room.where(workspace_id: workspace_id).order(:name)
    
    render json: { rooms: rooms.map { |r| { id: r.id, name: r.name } } }
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

  def new_user_for_company
    @company = Company.find(params[:id])
    @locked_company_user_type = params[:company_user_type].presence_in(User.company_user_types.keys) || 'booking_user'
    @user = User.new(role: 'user', company_user_type: @locked_company_user_type)
    @workspaces = @company.workspaces
    @selected_workspace_id = @workspaces.first&.id
  end

  def quick_status_change
    @company = Company.find(params[:id])
    
    if current_user.super_admin?
      # Super admin can toggle between active and inactive
      new_status = @company.status == 'active' ? 'inactive' : 'active'
      @company.update(status: new_status)
      status_text = new_status == 'active' ? 'activated' : 'deactivated'
      redirect_to admin_companies_path, notice: "Company '#{@company.name}' has been #{status_text} successfully."
    else
      redirect_to admin_companies_path, alert: "Only Super Admin can change company status."
    end
  end

  private

  def set_company
    @company = Company.find(params[:id])
  end

  def company_params
    permitted_params = [:name, :email, :phone_number, :address, :cabin_number, :no_of_employee, :meeting_time_limit_per_month, :no_of_meeting_per_day, :meeting_time_limit_per_day, :minimum_minutes_meeting_limit, :max_minutes_meeting_limit, :parallel_booking, :email_notifications_enabled, :centre_address, :commencement_date, :lock_in_period, :no_of_seats, :floor_no, :shift_type, :agreement_date, :company_poc_contact, :company_email_address, :name_board_charges, :lease_expiry_date, :cost_per_seat]
    
    # Only super_admin can change status
    if current_user.super_admin?
      permitted_params << :status
    end
    
    params.require(:company).permit(permitted_params)
  end

  def calculate_usage_analytics(company)
    {
      total_users: company.users.count,
      total_bookings: company.bookings.count,
      this_month_bookings: company.bookings.where(created_at: Date.current.beginning_of_month..Date.current.end_of_month).count,
      active_users: company.users.joins(:company_users).where(company_users: { company_id: company.id }).count
    }
  end

  # This method is no longer needed as only super_admin can change status
end
