class Admin::UsersController < Admin::BaseController
  before_action :set_user, only: [:show, :edit, :update, :destroy]

  def index
    @search = params[:search]
    @users = User.includes(:workspaces)
    
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
  end

  def create
    @user = User.new(user_params)
    @user.password = params[:user][:password] if params[:user][:password].present?
    
    if @user.save
      redirect_to admin_users_path, notice: 'User was successfully created.'
    else
      render :new
    end
  end

  def edit
  end

  def update
    user_update_params = user_params
    user_update_params[:password] = params[:user][:password] if params[:user][:password].present?
    
    if @user.update(user_update_params)
      redirect_to admin_user_path(@user), notice: 'User was successfully updated.'
    else
      render :edit
    end
  end

  def destroy
    @user.destroy
    redirect_to admin_users_path, notice: 'User was successfully deleted.'
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
