class Api::WorkspacesController < Api::BaseController
  # skip_before_action :authenticate_user!, only: [:search_by_phone_number]
  before_action :authenticate_user!
  before_action :set_workspace

  # GET /api/workspaces/search_by_phone_number?phone_number=...
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
