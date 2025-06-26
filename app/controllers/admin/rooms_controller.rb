class Admin::RoomsController < Admin::BaseController
  before_action :set_workspace
  before_action :set_room, only: [:show, :edit, :update, :destroy]

  def index
    @rooms = @workspace.rooms
  end

  def show
  end

  def new
    @room = @workspace.rooms.build
  end

  def create
    @room = @workspace.rooms.build(room_params)
    
    if @room.save
      redirect_to admin_workspace_rooms_path(@workspace), notice: 'Room was successfully created.'
    else
      render :new
    end
  end

  def edit
  end

  def update
    if @room.update(room_params)
      redirect_to admin_workspace_room_path(@workspace, @room), notice: 'Room was successfully updated.'
    else
      render :edit
    end
  end

  def destroy
    @room.destroy
    redirect_to admin_workspace_rooms_path(@workspace), notice: 'Room was successfully deleted.'
  end

  private

  def set_workspace
    @workspace = Workspace.find(params[:workspace_id])
  end

  def set_room
    @room = @workspace.rooms.find(params[:id])
  end

  def room_params
    params.require(:room).permit(:name, :category, :capacity, :whiteboard, :projector, :is_available)
  end
end
