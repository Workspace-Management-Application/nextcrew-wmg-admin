class Admin::RoomsController < Admin::BaseController
  before_action :set_workspace, only: [:new, :create, :show, :edit, :update, :destroy]
  before_action :set_room, only: [:show, :edit, :update, :destroy]

  def index
    @search = params[:search]
    
    # All rooms from user's workspaces
    user_workspace_ids = current_user.workspaces.pluck(:id)
    @rooms = Room.joins(:workspace).where(workspace_id: user_workspace_ids).includes(:workspace, :bookings, :amenities)
    
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
    @rooms = @rooms.order(created_at: :desc)
    
    # Pagination
    @rooms = @rooms.page(params[:page]).per(10)
  end

  def show
    # Global room view - find room from user's workspaces
    user_workspace_ids = current_user.workspaces.pluck(:id)
    @room = Room.joins(:workspace).where(workspace_id: user_workspace_ids).includes(:amenities).find(params[:id])
    @workspace = @room.workspace
  end

  def new
    @room = Room.new
    
    # If accessed via nested route, set the workspace
    if params[:workspace_id].present?
      @room.workspace = @workspace
    end
    
    @workspaces = current_user.workspaces.order(:name)
    @amenities = Amenity.order(:name)
  end

  def create
    # If accessed via nested route, use the workspace from the URL
    if params[:workspace_id].present?
      target_workspace = @workspace
    else
      # If accessed via standalone route, use the workspace from the form
      workspace_id = params[:room][:workspace_id]
      target_workspace = current_user.workspaces.find(workspace_id)
    end
    
    @room = target_workspace.rooms.build(room_params.except(:photo, :amenity_ids, :workspace_id))
    
    if @room.save
      # Handle amenity associations
      handle_amenity_associations(@room, params[:room][:amenity_ids])
      
      # Handle photo upload using Active Storage with auto folder organization
      if params[:room][:photo].present?
        photo_result = PhotoUploadService.attach_photo_auto(@room, params[:room][:photo])
        unless photo_result[:success]
          flash[:alert] = photo_result[:error]
          @workspaces = current_user.workspaces.order(:name)
          @amenities = Amenity.order(:name)
          render :new
          return
        end
      end
      
              # Redirect based on the route context
        if params[:workspace_id].present?
          redirect_to admin_workspace_path(target_workspace), notice: 'Room was successfully created.'
        else
        redirect_to admin_rooms_path, notice: 'Room was successfully created.'
      end
    else
      @workspaces = current_user.workspaces.order(:name)
      @amenities = Amenity.order(:name)
      render :new
    end
  end

  def edit
    @amenities = Amenity.order(:name)
  end

  def update
    if @room.update(room_params.except(:photo, :amenity_ids))
      # Handle amenity associations
      handle_amenity_associations(@room, params[:room][:amenity_ids])
      
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
      @amenities = Amenity.order(:name)
      render :edit
    end
  end

  def destroy
    workspace = @room.workspace
    @room.destroy
    
    # Redirect based on the route context
    if params[:workspace_id].present?
      redirect_to admin_workspace_path(workspace), notice: 'Room was successfully deleted.'
    else
      redirect_to admin_rooms_path, notice: 'Room was successfully deleted.'
    end
  end

  private

  def set_workspace
    @workspace = Workspace.find(params[:workspace_id]) if params[:workspace_id].present?
  end

  def set_room
    if params[:workspace_id].present?
      # Workspace-scoped room (for edit/update/delete)
      @room = @workspace.rooms.includes(:amenities).find(params[:id])
    else
      # Global room view
      user_workspace_ids = current_user.workspaces.pluck(:id)
      @room = Room.joins(:workspace).where(workspace_id: user_workspace_ids).includes(:amenities).find(params[:id])
      @workspace = @room.workspace
    end
  end

  def room_params
    params.require(:room).permit(:name, :category, :capacity, :price_per_hour, :is_available, :photo, :workspace_id, amenity_ids: [])
  end

  def handle_amenity_associations(room, amenity_ids)
    return unless amenity_ids.present?
    
    # Clear existing associations
    room.room_amenities.destroy_all
    
    # Create new associations
    amenity_ids.each do |amenity_id|
      next if amenity_id.blank?
      amenity = Amenity.find(amenity_id)
      RoomAmenity.create!(room: room, amenity: amenity, has_amenity: true)
    end
  end
end
