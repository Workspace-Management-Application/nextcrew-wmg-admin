class Admin::WorkspacesController < Admin::BaseController
  before_action :set_workspace, only: [:show, :edit, :update, :destroy, :step2, :step3, :update_step2, :update_step3, :step1, :update_step1]
  before_action :check_workspace_status, only: [:step2, :step3, :update_step2, :update_step3]

  def index
    @search = params[:search]
    @workspaces = current_user.workspaces.includes(:companies, :users, :rooms, :workspace_types).order(created_at: :desc)
    
    # Search functionality
    if @search.present?
      @workspaces = @workspaces.where(
        "name ILIKE ? OR building_name ILIKE ? OR city ILIKE ? OR address ILIKE ? OR pincode ILIKE ?",
        "%#{@search}%", "%#{@search}%", "%#{@search}%", "%#{@search}%", "%#{@search}%"
      )
    end
    
    # Filter by status if specified
    if params[:filter].present?
      case params[:filter]
      when 'active'
        @workspaces = @workspaces.where(is_active: true, status: 'completed')
      when 'inactive'
        @workspaces = @workspaces.where(is_active: false, status: 'completed')
      when 'pending'
        @workspaces = @workspaces.where(status: 'pending')
      end
    else
      # Show completed workspaces by default
      @workspaces = @workspaces.where(status: 'completed')
    end
    
    # Order by name
    @workspaces = @workspaces.order(:name)
    
    # Pagination
    @workspaces = @workspaces.page(params[:page]).per(10)

    # Find a pending workspace for resume/start over UI
    @pending_workspaces = current_user.workspaces.pending
  end

  def show
    @rooms = @workspace.rooms
    @available_companies = @workspace.companies.where(status: ['active']).left_joins(:company_workspaces).where(company_workspaces: { id: nil })
  end

  def new
    @workspace = Workspace.new(status: 'pending', wizard_step: 1)
    respond_to do |format|
      format.html
      format.js { render partial: 'admin/workspaces/step1_details', locals: { workspace: @workspace } }
    end
  end

  def create
    @workspace = Workspace.new(workspace_params)
    @workspace.status = 'pending'
    @workspace.wizard_step = 1
    @workspace.is_active = true
    
    if @workspace.save
      # Assign the creator as a user of this workspace
      UserWorkspace.create!(user: current_user, workspace: @workspace) unless current_user.super_admin?
      # Handle photo upload using Active Storage with auto folder organization
      if params[:workspace][:photo].present?
        photo_result = PhotoUploadService.attach_photo_auto(@workspace, params[:workspace][:photo])
        unless photo_result[:success]
          flash[:alert] = photo_result[:error]
          render :new
          return
        end
      end
      
      respond_to do |format|
        format.html { redirect_to step2_admin_workspace_path(@workspace), notice: 'Step 1 completed successfully!' }
        format.json { render json: { next_step: 2, workspace_id: @workspace.id } }
      end
    else
      respond_to do |format|
        format.html { render :new }
        format.json { render partial: 'admin/workspaces/step1_details', status: :unprocessable_entity }
      end
    end
  end

  def edit
  end

  def update
    if @workspace.update(workspace_params)
      # Handle photo upload using Active Storage with auto folder organization
      if params[:workspace][:photo].present?
        photo_result = PhotoUploadService.attach_photo_auto(@workspace, params[:workspace][:photo])
        unless photo_result[:success]
          flash[:alert] = photo_result[:error]
          render :edit
          return
        end
      end
      
      redirect_to admin_workspace_path(@workspace), notice: 'Workspace was successfully updated.'
    else
      render :edit
    end
  end

  def destroy
    @workspace.destroy
    redirect_to admin_workspaces_path, notice: 'Workspace was successfully deleted.'
  end

  def add_company
    @workspace = Workspace.find(params[:id])
    @company = Company.find(params[:company_id])
    
    unless @workspace.companies.include?(@company)
      @workspace.companies << @company
      redirect_to admin_workspace_path(@workspace), notice: "Company added to workspace successfully."
    else
      redirect_to admin_workspace_path(@workspace), alert: "Company is already assigned to this workspace."
    end
  end

  def remove_company
    @workspace = Workspace.find(params[:id])
    @company = Company.find(params[:company_id])
    @workspace.companies.delete(@company)
    redirect_to admin_workspace_path(@workspace), notice: "Company removed from workspace."
  end

  # Multi-step wizard methods
  def step1
    @workspace = Workspace.find(params[:id])
    render :step1
  end

  def update_step1
    @workspace = Workspace.find(params[:id])
    if @workspace.update(workspace_params)
      redirect_to step2_admin_workspace_path(@workspace)
    else
      render :step1
    end
  end

  def step2
    @workspace.update(wizard_step: 2) unless @workspace.wizard_step >= 2
    @available_users = User.where(role: ['floor_user'])
                          .left_joins(:user_workspaces)
                          .where(user_workspaces: { id: nil })
                          .order(:name)
    @assigned_floor_users = @workspace.users.where(role: 'floor_user')
    respond_to do |format|
      format.html
      format.js { render partial: 'admin/workspaces/step2_user', locals: { workspace: @workspace, available_users: @available_users, assigned_floor_users: @assigned_floor_users } }
    end
  end

  def update_step2
    # Handle user assignment
    if params[:user_action] == 'create_new'
      # Create new user
      user = User.new(user_params)
      # Only set password if provided in params
      user.password = user_params[:password] if user_params[:password].present?
      if user.save
        UserWorkspace.create!(user: user, workspace: @workspace)
        @workspace.update(wizard_step: 3)
        respond_to do |format|
          format.html { redirect_to step3_admin_workspace_path(@workspace), notice: 'User created and assigned successfully!' }
          format.json { render json: { next_step: 3, workspace_id: @workspace.id } }
        end
      else
        @user = user
        @available_users = User.where(role: ['floor_user'])
                              .left_joins(:user_workspaces)
                              .where(user_workspaces: { id: nil })
                              .order(:name)
        respond_to do |format|
          format.html { render :step2 }
          format.json { render partial: 'admin/workspaces/step2_user', status: :unprocessable_entity }
        end
      end
    elsif params[:user_action] == 'assign_existing'
      # Assign existing user
      user = User.find(params[:user_id])
      UserWorkspace.create!(user: user, workspace: @workspace)
      @workspace.update(wizard_step: 3)
      respond_to do |format|
        format.html { redirect_to step3_admin_workspace_path(@workspace), notice: 'User assigned successfully!' }
        format.json { render json: { next_step: 3, workspace_id: @workspace.id } }
      end
    else
      respond_to do |format|
        format.html { redirect_to step2_admin_workspace_path(@workspace), alert: 'Please select an action.' }
        format.json { render partial: 'admin/workspaces/step2_user', status: :unprocessable_entity }
      end
    end
  end

  def step3
    @workspace.update(wizard_step: 3) unless @workspace.wizard_step >= 3
    # Build a new room if none exist to ensure the form has a template
    if @workspace.rooms.empty?
      @workspace.rooms.build
    end
    @rooms = @workspace.rooms
    @amenities = Amenity.order(:name)
    respond_to do |format|
      format.html
      format.js { render partial: 'admin/workspaces/step3_rooms', locals: { workspace: @workspace, rooms: @rooms, amenities: @amenities } }
    end
  end

  def update_step3
    unless params[:workspace].nil?
      if @workspace.update(workspace_params)
        @workspace.update(wizard_step: 3, status:"completed")
        
        respond_to do |format|
          format.html { redirect_to admin_workspaces_path, notice: 'Rooms created successfully!' }
          format.json { render json: { redirect_url: admin_workspaces_path } }
        end
      else
        @rooms = @workspace.rooms.includes(:amenities)
        @amenities = Amenity.order(:name)
        respond_to do |format|
          format.html { render :step3 }
          format.json { render partial: 'admin/workspaces/step3_rooms', status: :unprocessable_entity }
        end
      end
    else
      @workspace.update(wizard_step: 3, status:"completed")
      redirect_to admin_workspaces_path, notice: 'Workspace created successfully!'
    end

  end

  def resume
    # Find the pending workspace by id param (if provided), else fallback to the first pending workspace
    workspace_id = params[:id] || @pending_workspace&.id
    workspace = Workspace.find_by(id: workspace_id, status: 'pending')
    if workspace
      redirect_to determine_next_step(workspace)
    else
      redirect_to admin_workspaces_path, alert: 'No pending workspace found.'
    end
  end

  def start_over
    @pending_workspace = Workspace.find_by(id: params[:id])
    @pending_workspace&.destroy
    redirect_to new_admin_workspace_path
  end

  private

  def set_workspace
    @workspace = Workspace.includes(:workspace_types).find(params[:id])
  end

  def check_workspace_status
    unless @workspace.pending?
      redirect_to admin_workspaces_path, alert: 'This workspace is not in pending status.'
    end
  end

  def determine_next_step(workspace)
    has_floor_user = workspace.users.where(role: 'floor_user').exists?
    if !has_floor_user
      step2_admin_workspace_path(workspace)
    else
      step3_admin_workspace_path(workspace)
    end
  end

  def workspace_params
    # First permit the basic workspace attributes
    base_params = params.require(:workspace).permit(
      :name, :building_name, :city, :address, :pincode, :is_active, :photo, 
      workspace_type_ids: []
    )
    
    # Handle rooms_attributes manually to support Cocoon's dynamic keys
    if params[:workspace][:rooms_attributes].present?
      rooms_attrs = {}
      params[:workspace][:rooms_attributes].each do |key, room_params|
        rooms_attrs[key] = room_params.permit(
          :id, :name, :category, :capacity, :price_per_hour, :is_available, :photo, :_destroy,
          amenity_ids: []
        )
      end
      base_params[:rooms_attributes] = rooms_attrs
    end
    
    base_params
  end

  def user_params
    params.require(:user).permit(:name, :email, :phone_number, :role, :password)
  end

  def company_params
    params.require(:company).permit(:name, :email, :phone_number, :address, :cabin_number, 
                                   :no_of_employee, :meeting_time_limit_per_month, :no_of_meeting_per_day,
                                   :meeting_time_limit_per_day, :minimum_minutes_meeting_limit, :max_minutes_meeting_limit)
  end
end
