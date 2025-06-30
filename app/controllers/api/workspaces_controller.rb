class Api::WorkspacesController < Api::BaseController
  before_action :set_workspace

  def get_data_for_room
    company = @workspace.companies.find_by(id: params[:company_id])
    room =  company.rooms
    if room && company
      render_success(room)
    else
      render_error("Room not found", :not_found)
    end
  end

  def search_by_phone_number
    company = @workspace.companies.find_by(phone_number: params[:phone_number])
    if company
      render_success(company)
    else
      render_error("Company not found", :not_found)
    end
  end

  def set_workspace
    @workspace = Workspace.find_by(id: params[:id])
  end
end
