class Api::WorkspacesController < Api::BaseController
  before_action :set_workspace

  def get_data_for_room
    company = @workspace.companies.find_by(id: params[:company_id])
    rooms = company.rooms.where(is_available: true)
    if rooms && company
      rooms_with_occupancy = rooms.map do |room|
        room.as_json(except: [:created_at, :updated_at, :workspace_id]).merge(
          is_occupied: room.is_occupied?,
          workspace_name: @workspace.name
        )
      end
      render_success(rooms_with_occupancy)
    else
      render_error("Room not found", :not_found)
    end
  end

  def search_by_phone_number
    company = @workspace.companies.find_by(phone_number: params[:phone_number])
    if company
      render_success(company)
    else
      render_error("Please enter registered phone number", :not_found)
    end
  end

  def workspace_types
    workspace_types = @workspace.workspace_types
    render_success(workspace_types)
  end

  def company_today_bookings
    company = @workspace.companies.find_by(id: params[:company_id])
    
    if company
      today_bookings = Booking.joins(:room, :company)
                             .where(rooms: { workspace_id: @workspace.id })
                             .where('DATE(bookings.start_time) = ?', Date.current)
                             .includes(:room, :company).order(:start_time)
      
      bookings_with_room_name = today_bookings.map do |booking|
        booking.as_json(except: [ :company_id, :room_id, :created_at, :updated_at]).merge(
          room_name: booking.room.name,
          company_name: booking.company.name,
          phone_number: booking.company.phone_number
        )
      end
      
      render_success(bookings_with_room_name)
    else
      render_error("Company not found", :not_found)
    end
  end

  def set_workspace
    @workspace = Workspace.find_by(id: params[:id])
  end
end
