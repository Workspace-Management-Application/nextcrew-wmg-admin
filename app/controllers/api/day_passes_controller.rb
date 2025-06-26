class Api::DayPassesController < Api::BaseController
  before_action :set_workspace
  before_action :set_day_pass, only: [:show, :update, :destroy]
  before_action :authorize_floor_user!

  # GET /api/workspaces/:workspace_id/day_passes
  def index
    day_passes = @workspace.day_passes
    render_success(day_passes)
  end

  # GET /api/workspaces/:workspace_id/day_passes/:id
  def show
    if @day_pass
      render_success(@day_pass)
    else
      render_error('Day pass not found', :not_found)
    end
  end

  # POST /api/workspaces/:workspace_id/day_passes
  def create
    day_pass = @workspace.day_passes.new(day_pass_params.except(:photo))
    if params[:photo].present?
      photo_url = S3Uploader.upload(params[:photo], folder: 'day_pass_photos')
      day_pass.photo = photo_url
    end
    if day_pass.save
      render_success(day_pass, 'Day pass created successfully', :created)
    else
      render_error(day_pass.errors.full_messages.join(', '))
    end
  end

  # PATCH/PUT /api/workspaces/:workspace_id/day_passes/:id
  def update
    if @day_pass
      if params[:photo].present?
        photo_url = S3Uploader.upload(params[:photo], folder: 'day_pass_photos')
        @day_pass.photo = photo_url
      end
      if @day_pass.update(day_pass_params.except(:photo))
        render_success(@day_pass, 'Day pass updated successfully')
      else
        render_error(@day_pass.errors.full_messages.join(', '))
      end
    else
      render_error('Day pass not found', :not_found)
    end
  end

  # DELETE /api/workspaces/:workspace_id/day_passes/:id
  def destroy
    if @day_pass
      @day_pass.destroy
      render_success({}, 'Day pass deleted successfully')
    else
      render_error('Day pass not found', :not_found)
    end
  end

  private

  def set_workspace
    @workspace = Workspace.find_by(id: params[:workspace_id])
    render_error('Workspace not found', :not_found) unless @workspace
  end

  def set_day_pass
    @day_pass = @workspace.day_passes.find_by(id: params[:id])
  end

  def day_pass_params
    params.require(:day_pass).permit(:name, :phone_number, :email, :company_name, :pass_date, :purpose, :photo)
  end

  def authorize_floor_user!
    unless current_user&.role == 'floor_user'
      render_error('Forbidden: Only floor users allowed', :forbidden)
    end
  end
end 