class Admin::WorkspacesController < Admin::BaseController
  before_action :set_workspace, only: [:show, :edit, :update, :destroy]

  def index
    @workspaces = Workspace.all
  end

  def show
    @rooms = @workspace.rooms
  end

  def new
    @workspace = Workspace.new
  end

  def create
    @workspace = Workspace.new(workspace_params.except(:photo))
    
    if @workspace.save
      # Handle photo upload using Active Storage with auto folder organization
      if params[:workspace][:photo].present?
        photo_result = PhotoUploadService.attach_photo_auto(@workspace, params[:workspace][:photo])
        unless photo_result[:success]
          flash[:alert] = photo_result[:error]
          render :new
          return
        end
      end
      
      redirect_to admin_workspaces_path, notice: 'Workspace was successfully created.'
    else
      render :new
    end
  end

  def edit
  end

  def update
    if @workspace.update(workspace_params.except(:photo))
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

  private

  def set_workspace
    @workspace = Workspace.find(params[:id])
  end

  def workspace_params
    params.require(:workspace).permit(:name, :building_name, :city, :address, :pincode, :is_active, :photo)
  end
end
