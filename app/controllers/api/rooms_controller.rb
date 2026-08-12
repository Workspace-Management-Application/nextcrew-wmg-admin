class Api::RoomsController < Api::BaseController
  before_action :set_workspace
  before_action :set_room, only: [:show, :update, :destroy]

  # GET /api/workspaces/:workspace_id/rooms
  def index
    rooms = @workspace.rooms
    rooms_with_occupancy = rooms.map do |room|
      room_response(room).merge(
        is_occupied: room.is_occupied?,
        workspace_name: @workspace.name
      )
    end
    render_success(rooms_with_occupancy)
  end

  # GET /api/workspaces/:workspace_id/rooms/:id
  def show
    if @room
      room_data = room_response(@room).merge(
        workspace_name: @workspace.name
      )
      if params[:date].present?
        date = Date.parse(params[:date]) rescue nil
        if date
          bookings = Booking.where(room_id: @room.id)
                            .where('start_time >= ? AND start_time < ?', date.beginning_of_day, date.next_day.beginning_of_day)
          room_data[:bookings] = bookings.as_json(except: [:created_at, :updated_at])
        else
          room_data[:bookings] = []
        end
      end
      render_success(room_data)
    else
      render_error('Room not found', :not_found)
    end
  end

  # POST /api/workspaces/:workspace_id/rooms
  def create
    room = @workspace.rooms.new(room_params.except(:photo))
    
    if room.save
      # Handle photo upload using Active Storage with auto folder organization
      if params[:room][:photo].present?
        photo_result = PhotoUploadService.attach_photo_auto(room, params[:room][:photo])
        unless photo_result[:success]
          render_error(photo_result[:error])
          return
        end
      end
      
      data = room_response(room).merge(workspace_name: room.workspace.name)
      render_success(data, 'Room created successfully', :created)
    else
      render_error(room.errors.full_messages.join(', '))
    end
  end

  # PATCH/PUT /api/workspaces/:workspace_id/rooms/:id
  def update
    if @room
      if @room.update(room_params.except(:photo))
        # Handle photo upload using Active Storage with auto folder organization
        if params[:room][:photo].present?
          photo_result = PhotoUploadService.attach_photo_auto(@room, params[:room][:photo])
          unless photo_result[:success]
            render_error(photo_result[:error])
            return
          end
        end
        
        data = room_response(@room).merge(workspace_name: @workspace.name)
        render_success(data, 'Room updated successfully')
      else
        render_error(@room.errors.full_messages.join(', '))
      end
    else
      render_error('Room not found', :not_found)
    end
  end

  # DELETE /api/workspaces/:workspace_id/rooms/:id
  def destroy
    if @room
      @room.destroy
      render_success({}, 'Room deleted successfully')
    else
      render_error('Room not found', :not_found)
    end
  end

  private

  def set_workspace
    @workspace = Workspace.find_by(id: params[:workspace_id])
    render_error('Workspace not found', :not_found) unless @workspace
  end

  def set_room
    @room = @workspace.rooms.find_by(id: params[:id])
  end

  def room_params
    params.require(:room).permit(:name, :category, :capacity, :price_per_hour, :whiteboard, :projector, :is_available, :photo)
  end

  def room_response(room)
    room.as_json(except: [:created_at, :updated_at, :workspace_id]).merge(
      photo_url: PhotoUploadService.photo_url(room),
      photo_attached: PhotoUploadService.photo_attached?(room)
    )
  end
end 
