class Admin::RoomsController < Admin::BaseController
  before_action :set_workspace, only: [:new, :create, :edit, :update, :destroy]
  before_action :set_room, only: [:show, :edit, :update, :destroy]

  def index
    @search = params[:search]
    
    # All rooms from user's workspaces
    user_workspace_ids = current_user.workspaces.pluck(:id)
    @rooms = Room.joins(:workspace).where(workspace_id: user_workspace_ids).includes(:workspace, :bookings)
    
    # Search functionality
    if @search.present?
      @rooms = @rooms.where(
        "rooms.name ILIKE ? OR rooms.category ILIKE ? OR workspaces.name ILIKE ?",
        "%#{@search}%", "%#{@search}%", "%#{@search}%"
      )
    end
    
    # Filter by category if specified
    if params[:filter].present?
      @rooms = @rooms.where(category: params[:filter])
    end
    
    # Filter by availability if specified
    if params[:availability].present?
      is_available = params[:availability] == 'available'
      @rooms = @rooms.where(is_available: is_available)
    end
    
    # Filter by workspace if specified
    if params[:workspace_id].present?
      @rooms = @rooms.where(workspace_id: params[:workspace_id])
    end
    
    # Order by workspace name, then room name
    @rooms = @rooms.order('workspaces.name, rooms.name')
    
    # Pagination
    @rooms = @rooms.page(params[:page]).per(10)
  end

  def show
    # Global room view - find room from user's workspaces
    user_workspace_ids = current_user.workspaces.pluck(:id)
    @room = Room.joins(:workspace).where(workspace_id: user_workspace_ids).find(params[:id])
    @workspace = @room.workspace
  end

  def new
    @room = @workspace.rooms.build
  end

  def create
    @room = @workspace.rooms.build(room_params.except(:photo))
    
    if @room.save
      # Handle photo upload using Active Storage with auto folder organization
      if params[:room][:photo].present?
        photo_result = PhotoUploadService.attach_photo_auto(@room, params[:room][:photo])
        unless photo_result[:success]
          flash[:alert] = photo_result[:error]
          render :new
          return
        end
      end
      
      redirect_to admin_rooms_path, notice: 'Room was successfully created.'
    else
      render :new
    end
  end

  def edit
  end

  def update
    if @room.update(room_params.except(:photo))
      # Handle photo upload using Active Storage with auto folder organization
      if params[:room][:photo].present?
        photo_result = PhotoUploadService.attach_photo_auto(@room, params[:room][:photo])
        unless photo_result[:success]
          flash[:alert] = photo_result[:error]
          render :edit
          return
        end
      end
      
      redirect_to admin_room_path(@room), notice: 'Room was successfully updated.'
    else
      render :edit
    end
  end

  def destroy
    @room.destroy
    redirect_to admin_rooms_path, notice: 'Room was successfully deleted.'
  end

  private

  def set_workspace
    @workspace = Workspace.find(params[:workspace_id])
  end

  def set_room
    if params[:workspace_id].present?
      # Workspace-scoped room (for edit/update/delete)
      @room = @workspace.rooms.find(params[:id])
    else
      # Global room view
      user_workspace_ids = current_user.workspaces.pluck(:id)
      @room = Room.joins(:workspace).where(workspace_id: user_workspace_ids).find(params[:id])
      @workspace = @room.workspace
    end
  end

  def room_params
    params.require(:room).permit(:name, :category, :capacity, :whiteboard, :projector, :tv, :is_available, :photo)
  end
end
