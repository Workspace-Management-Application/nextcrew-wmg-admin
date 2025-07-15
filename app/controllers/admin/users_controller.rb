class Admin::UsersController < Admin::BaseController
  before_action :set_user, only: [:show, :edit, :update, :destroy]

  def index
    @search = params[:search]
    workspace_ids = current_user.workspaces.pluck(:id)
    @users = User.joins(:user_workspaces)
                 .where(user_workspaces: { workspace_id: workspace_ids })
                 .distinct
                 .includes(:workspaces)

    unless current_user.super_admin?
      @users = @users.where.not(role: 'super_admin')
    end
    
    # Search functionality
    if @search.present?
      @users = @users.where(
        "name ILIKE ? OR email ILIKE ? OR role ILIKE ?",
        "%#{@search}%", "%#{@search}%", "%#{@search}%"
      )
    end
    
    # Filter by role if specified
    if params[:role].present?
      @users = @users.where(role: params[:role])
    end
    
    # Order by name
    @users = @users.order(:name)
    
    # Pagination
    @users = @users.page(params[:page]).per(10)
  end

  def show
  end

  def new
    @user = User.new
    @workspaces = current_user.workspaces
  end

  def create
    @user = User.new(user_params)
    @user.password = params[:user][:password] if params[:user][:password].present?
    if @user.save
      # Assign workspace if selected
      if params[:user][:workspace_id].present?
        @user.user_workspaces.create(workspace_id: params[:user][:workspace_id])
      end
      
      # Assign company if selected (for user role)
      if params[:user][:company_id].present? && @user.user?
        @user.company_users.create(company_id: params[:user][:company_id])
      end
      
      redirect_to admin_users_path, notice: 'User was successfully created.'
    else
      @workspaces = Workspace.all
      render :new
    end
  end

  def edit
    @workspaces = current_user.workspaces
  end

  def update
    user_update_params = user_params
    user_update_params[:password] = params[:user][:password] if params[:user][:password].present?
    if @user.update(user_update_params)
      # Update workspace assignment
      if params[:user][:workspace_id].present?
        @user.user_workspaces.destroy_all
        @user.user_workspaces.create(workspace_id: params[:user][:workspace_id])
      else
        @user.user_workspaces.destroy_all
      end
      
      # Update company assignment (for user role)
      if @user.user?
        if params[:user][:company_id].present?
          @user.company_users.destroy_all
          @user.company_users.create(company_id: params[:user][:company_id])
        else
          @user.company_users.destroy_all
        end
      end
      
      redirect_to admin_user_path(@user), notice: 'User was successfully updated.'
    else
      @workspaces = Workspace.all
      render :edit
    end
  end

  def destroy
    @user.destroy
    redirect_to admin_users_path, notice: 'User was successfully deleted.'
  end

  # API endpoint to get companies for a specific workspace
  def companies_for_workspace
    workspace_id = params[:workspace_id]
    companies = Company.joins(:company_workspaces)
                      .where(company_workspaces: { workspace_id: workspace_id })
                      .order(:name)
    
    render json: { companies: companies.map { |c| { id: c.id, name: c.name } } }
  end

  # Super Admin only - assign workspace to admin users
  def assign_workspace
    return unless current_user.super_admin?
    
    @user = User.find(params[:id])
    @workspaces = Workspace.all
    
    if request.patch?
      if params[:workspace_ids].present?
        # Clear existing assignments
        @user.user_workspaces.destroy_all
        
        # Create new assignments for selected workspaces
        params[:workspace_ids].each do |workspace_id|
          UserWorkspace.create(user: @user, workspace_id: workspace_id) if workspace_id.present?
        end
        
        redirect_to assign_workspace_admin_user_path(@user), notice: 'Workspaces assigned successfully.'
      elsif params[:remove_workspace_id].present?
        # Remove specific workspace assignment
        @user.user_workspaces.where(workspace_id: params[:remove_workspace_id]).destroy_all
        redirect_to assign_workspace_admin_user_path(@user), notice: 'Workspace removed successfully.'
      else
        # Remove all workspace assignments
        @user.user_workspaces.destroy_all
        redirect_to assign_workspace_admin_user_path(@user), notice: 'All workspace assignments removed successfully.'
      end
    end
  end

  private

  def set_user
    @user = User.find(params[:id])
  end

  def user_params
    params.require(:user).permit(:name, :email, :phone_number, :role)
  end
end
