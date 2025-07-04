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

  def set_workspace
    @workspace = Workspace.find_by(id: params[:id])
  end
end
