class Api::WorkspacesController < Api::BaseController
  # skip_before_action :authenticate_user!, only: [:search_by_phone_number]
  before_action :authenticate_user!

  # GET /api/workspaces/search_by_phone_number?phone_number=...
  def search_by_phone_number
    company = Company.find_by(phone_number: params[:phone_number])
    if company
      render json: { company: company.as_json(only: [:id, :name, :email, :phone_number, :address, :status]) }, status: :ok
    else
      render json: { error: 'Company not found' }, status: :not_found
    end
  end
end
