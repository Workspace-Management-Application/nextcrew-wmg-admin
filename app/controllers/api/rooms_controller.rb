class Api::RoomsController < Api::BaseController
  before_action :set_workspace
  before_action :set_room, only: [:show, :update, :destroy]

  # GET /api/workspaces/:workspace_id/rooms
  def index
    rooms = @workspace.rooms
    rooms_with_occupancy = rooms.map do |room|
      room.as_json(except: [:created_at, :updated_at]).merge(is_occupied: room.is_occupied?)
    end
    render_success(rooms_with_occupancy)
  end

  # GET /api/workspaces/:workspace_id/rooms/:id
  def show
    if @room
      room_data = @room.as_json(except: [:created_at, :updated_at])
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
    room = @workspace.rooms.new(room_params)
    if room.save
      data = room.as_json(except: [:created_at, :updated_at]).merge(workspace_name: room.workspace.name)
      render_success(data, 'Room created successfully', :created)
    else
      render_error(room.errors.full_messages.join(', '))
    end
  end

  # PATCH/PUT /api/workspaces/:workspace_id/rooms/:id
  def update
    if @room
      if @room.update(room_params)
        render_success(@room, 'Room updated successfully')
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
    params.require(:room).permit(:name, :category, :capacity, :whiteboard, :projector, :is_available)
  end
end 