class Api::OfficeEnquiriesController < Api::BaseController
  before_action :set_workspace
  before_action :set_office_enquiry, only: [:show, :update, :destroy]
  before_action :authorize_floor_user!

  # GET /api/workspaces/:workspace_id/office_enquiries
  def index
    office_enquiries = @workspace.office_enquiries
    render_success(office_enquiries)
  end

  # GET /api/workspaces/:workspace_id/office_enquiries/:id
  def show
    if @office_enquiry
      render_success(@office_enquiry)
    else
      render_error('Office enquiry not found', :not_found)
    end
  end

  # POST /api/workspaces/:workspace_id/office_enquiries
  def create
    office_enquiry = @workspace.office_enquiries.new(office_enquiry_params.except(:photo))
    if params[:photo].present?
      photo_url = S3Uploader.upload(params[:photo], folder: 'office_enquiry_photos')
      office_enquiry.photo = photo_url
    end
    if office_enquiry.save
      render_success(office_enquiry, 'Office enquiry created successfully', :created)
    else
      render_error(office_enquiry.errors.full_messages.join(', '))
    end
  end

  # PATCH/PUT /api/workspaces/:workspace_id/office_enquiries/:id
  def update
    if @office_enquiry
      if params[:photo].present?
        photo_url = S3Uploader.upload(params[:photo], folder: 'office_enquiry_photos')
        @office_enquiry.photo = photo_url
      end
      if @office_enquiry.update(office_enquiry_params.except(:photo))
        render_success(@office_enquiry, 'Office enquiry updated successfully')
      else
        render_error(@office_enquiry.errors.full_messages.join(', '))
      end
    else
      render_error('Office enquiry not found', :not_found)
    end
  end

  # DELETE /api/workspaces/:workspace_id/office_enquiries/:id
  def destroy
    if @office_enquiry
      @office_enquiry.destroy
      render_success({}, 'Office enquiry deleted successfully')
    else
      render_error('Office enquiry not found', :not_found)
    end
  end

  private

  def set_workspace
    @workspace = Workspace.find_by(id: params[:workspace_id])
    render_error('Workspace not found', :not_found) unless @workspace
  end

  def set_office_enquiry
    @office_enquiry = @workspace.office_enquiries.find_by(id: params[:id])
  end

  def office_enquiry_params
    params.require(:office_enquiry).permit(:enquirer_name, :visitor_name, :phone_number, :email, :requirement, :company_name, :photo)
  end

  def authorize_floor_user!
    unless current_user&.role == 'floor_user'
      render_error('Forbidden: Only floor users allowed', :forbidden)
    end
  end
end 