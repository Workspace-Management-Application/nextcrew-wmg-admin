class Admin::WorkspaceTypesController < Admin::BaseController
  before_action :set_workspace_type, only: [:edit, :update, :destroy]

  def index
    @workspace_types = WorkspaceType.order(:name)
    @workspace_type = WorkspaceType.new
  end

  def create
    @workspace_type = WorkspaceType.new(workspace_type_params)
    
    if @workspace_type.save
      redirect_to admin_workspace_types_path, notice: 'Workspace type was successfully created.'
    else
      @workspace_types = WorkspaceType.order(:name)
      render :index
    end
  end

  def edit
  end

  def update
    if @workspace_type.update(workspace_type_params)
      redirect_to admin_workspace_types_path, notice: 'Workspace type was successfully updated.'
    else
      render :edit
    end
  end

  def destroy
    if @workspace_type.workspaces.any?
      redirect_to admin_workspace_types_path, alert: 'Cannot delete workspace type that is associated with workspaces.'
    else
      @workspace_type.destroy
      redirect_to admin_workspace_types_path, notice: 'Workspace type was successfully deleted.'
    end
  end

  private

  def set_workspace_type
    @workspace_type = WorkspaceType.find(params[:id])
  end

  def workspace_type_params
    params.require(:workspace_type).permit(:name)
  end
end 