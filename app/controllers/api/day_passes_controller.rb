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
    day_pass = @workspace.day_passes.new(day_pass_params.except(:photo, :id_proof))
    
    if day_pass.save
      # Handle photo upload using Active Storage with auto folder organization
      if params[:day_pass][:photo].present?
        photo_result = PhotoUploadService.attach_photo_auto(day_pass, params[:day_pass][:photo], 'photo')
        unless photo_result[:success]
          render_error(photo_result[:error])
          return
        end
      end
      
      # Handle ID proof upload using Active Storage with auto folder organization
      if params[:day_pass][:id_proof].present?
        id_proof_result = PhotoUploadService.attach_photo_auto(day_pass, params[:day_pass][:id_proof], 'id_proof')
        unless id_proof_result[:success]
          render_error(id_proof_result[:error])
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
      if @day_pass.update(day_pass_params.except(:photo, :id_proof))
        # Handle photo upload using Active Storage with auto folder organization
        if params[:day_pass][:photo].present?
          photo_result = PhotoUploadService.attach_photo_auto(@day_pass, params[:day_pass][:photo], 'photo')
          unless photo_result[:success]
            render_error(photo_result[:error])
            return
          end
        end
        
        # Handle ID proof upload using Active Storage with auto folder organization
        if params[:day_pass][:id_proof].present?
          id_proof_result = PhotoUploadService.attach_photo_auto(@day_pass, params[:day_pass][:id_proof], 'id_proof')
          unless id_proof_result[:success]
            render_error(id_proof_result[:error])
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
    params.require(:day_pass).permit(:name, :phone_number, :email, :company_name, :pass_date, :photo, :id_proof)
  end

  def authorize_floor_user!
    unless current_user&.role == 'floor_user'
      render_error('Forbidden: Only floor users allowed', :forbidden)
    end
  end

  def day_pass_response(day_pass)
    {
      id: day_pass.id,
      workspace_id: day_pass.workspace_id,
      name: day_pass.name,
      phone_number: day_pass.phone_number,
      email: day_pass.email,
      pass_date: day_pass.pass_date,
      company_name: day_pass.company_name,
      photo_url: PhotoUploadService.photo_url(day_pass, 'photo'),
      photo_attached: PhotoUploadService.photo_attached?(day_pass, 'photo'),
      id_proof_url: PhotoUploadService.photo_url(day_pass, 'id_proof'),
      id_proof_attached: PhotoUploadService.photo_attached?(day_pass, 'id_proof'),
      created_at: day_pass.created_at,
      updated_at: day_pass.updated_at
    }
  end
end 