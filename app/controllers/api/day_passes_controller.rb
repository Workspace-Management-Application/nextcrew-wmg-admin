class Api::DayPassesController < Api::BaseController
  before_action :set_workspace
  before_action :set_day_pass, only: [:show, :update, :destroy]
  before_action :authorize_floor_user!

  # GET /api/workspaces/:workspace_id/day_passes
  def index
    day_passes = @workspace.day_passes.map { |day_pass| day_pass_response(day_pass) }
    render_success(day_passes)
  end

  # GET /api/workspaces/:workspace_id/day_passes/:id
  def show
    if @day_pass
      render_success(day_pass_response(@day_pass))
    else
      render_error('Day pass not found', :not_found)
    end
  end

  # POST /api/workspaces/:workspace_id/day_passes
  def create
    day_pass = @workspace.day_passes.new(day_pass_params.except(:photo))
    
    if day_pass.save
      # Handle photo upload using Active Storage
      if params[:photo].present?
        photo_result = PhotoUploadService.attach_photo(day_pass, params[:photo])
        unless photo_result[:success]
          render_error(photo_result[:error])
          return
        end
      end
      
      render_success(day_pass_response(day_pass), 'Day pass created successfully', :created)
    else
      render_error(day_pass.errors.full_messages.join(', '))
    end
  end

  # PATCH/PUT /api/workspaces/:workspace_id/day_passes/:id
  def update
    if @day_pass
      if @day_pass.update(day_pass_params.except(:photo))
        # Handle photo upload using Active Storage
        if params[:photo].present?
          photo_result = PhotoUploadService.attach_photo(@day_pass, params[:photo])
          unless photo_result[:success]
            render_error(photo_result[:error])
            return
          end
        end
        
        render_success(day_pass_response(@day_pass), 'Day pass updated successfully')
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

  def day_pass_response(day_pass)
    day_pass.as_json.merge(
      photo_url: PhotoUploadService.photo_url(day_pass),
      photo_attached: PhotoUploadService.photo_attached?(day_pass)
    )
  end
end 