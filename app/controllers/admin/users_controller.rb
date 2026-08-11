class Admin::UsersController < Admin::BaseController
  before_action :set_user, only: [:show, :edit, :update, :destroy, :destroy_document]

  def index
    @search = params[:search]
    workspace_ids = current_user.workspaces.pluck(:id)
    @users = User.joins(:user_workspaces)
                 .where(user_workspaces: { workspace_id: workspace_ids })
                 .distinct
                 .includes(:workspaces).order(created_at: :desc)

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
    @user = User.new(sanitized_user_params)
    @user.password = params[:user][:password] if params[:user][:password].present?
    attach_user_documents(@user)

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
      @workspaces = current_user.workspaces
      render :new
    end
  end

  def edit
    @workspaces = current_user.workspaces
    
    # Ensure company is loaded for user role in edit form
    if @user.user? && @user.workspaces.first
      @selected_workspace_id = @user.workspaces.first.id
      @selected_company_id = @user.companies.first&.id
    end
    
    # Preload companies for the user's workspace to ensure they're available in the form
    if @user.user? && @user.workspaces.first
      @user_workspace_companies = @user.workspaces.first.companies
    end
  end

  def update
    user_update_params = sanitized_user_params
    user_update_params[:password] = params[:user][:password] if params[:user][:password].present?
    @user.assign_attributes(user_update_params)
    attach_user_documents(@user)

    if @user.save
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
      else
        @user.company_users.destroy_all
        @user.documents.purge
      end
      
      redirect_to admin_user_path(@user), notice: 'User was successfully updated.'
    else
      @workspaces = current_user.workspaces
      render :edit
    end
  end

  def destroy
    @user.destroy
    redirect_to admin_users_path, notice: 'User was successfully deleted.'
  end

  def destroy_document
    attachment = @user.documents.attachments.find_by(id: params[:attachment_id])

    if attachment
      attachment.purge
      redirect_to admin_user_path(@user), notice: 'Document was successfully deleted.'
    else
      redirect_to admin_user_path(@user), alert: 'Document not found.'
    end
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
    @sidebar_items = User::SIDEBAR_ITEMS
    
    if request.patch?
      if params[:assign_settings].present?
        # Clear existing assignments
        @user.user_workspaces.destroy_all
        
        # Create new assignments for selected workspaces
        Array(params[:workspace_ids]).each do |workspace_id|
          UserWorkspace.create(user: @user, workspace_id: workspace_id) if workspace_id.present?
        end

        if @user.admin?
          @user.update(sidebar_items: Array(params[:sidebar_items]) & User::SIDEBAR_ITEMS.keys)
        end
        
        redirect_to assign_workspace_admin_user_path(@user), notice: 'Admin settings updated successfully.'
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
    params.require(:user).permit(:name, :email, :phone_number, :role, :password, :workspace_id, :company_id, :company_user_type, documents: [])
  end

  def sanitized_user_params
    permitted = user_params.except(:documents, :password, :workspace_id, :company_id)

    unless permitted[:role] == 'user'
      permitted.delete(:company_user_type)
    end

    permitted
  end

  def attach_user_documents(user)
    return unless user.user?
    return unless params[:user][:documents].present?

    user.documents.attach(params[:user][:documents].reject(&:blank?))
  end
end
