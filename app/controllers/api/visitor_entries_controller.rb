class Api::VisitorEntriesController < Api::BaseController
  before_action :set_workspace
  before_action :set_visitor_entry, only: [:show, :update, :destroy]
  before_action :authorize_floor_user!

  # GET /api/workspaces/:workspace_id/visitor_entries
  def index
    visitor_entries = @workspace.visitor_entries.map { |visitor_entry| visitor_entry_response(visitor_entry) }
    render_success(visitor_entries)
  end

  # GET /api/workspaces/:workspace_id/visitor_entries/:id
  def show
    if @visitor_entry
      render_success(visitor_entry_response(@visitor_entry))
    else
      render_error('Visitor entry not found', :not_found)
    end
  end

  # POST /api/workspaces/:workspace_id/visitor_entries
  def create
    visitor_entry = @workspace.visitor_entries.new(visitor_entry_params.except(:photo))
    
    if visitor_entry.save
      # Handle photo upload using Active Storage with auto folder organization
      if params[:visitor_entry][:photo].present?
        photo_result = PhotoUploadService.attach_photo_auto(visitor_entry, params[:visitor_entry][:photo])
        unless photo_result[:success]
          render_error(photo_result[:error])
          return
        end
      end
      
      render_success(visitor_entry_response(visitor_entry), 'Visitor entry created successfully', :created)
    else
      render_error(visitor_entry.errors.full_messages.join(', '))
    end
  end

  # PATCH/PUT /api/workspaces/:workspace_id/visitor_entries/:id
  def update
    if @visitor_entry
      if @visitor_entry.update(visitor_entry_params.except(:photo))
        # Handle photo upload using Active Storage with auto folder organization
        if params[:visitor_entry][:photo].present?
          photo_result = PhotoUploadService.attach_photo_auto(@visitor_entry, params[:visitor_entry][:photo])
          unless photo_result[:success]
            render_error(photo_result[:error])
            return
          end
        end
        
        render_success(visitor_entry_response(@visitor_entry), 'Visitor entry updated successfully')
      else
        render_error(@visitor_entry.errors.full_messages.join(', '))
      end
    else
      render_error('Visitor entry not found', :not_found)
    end
  end

  # DELETE /api/workspaces/:workspace_id//visitor_entries/:id
  def destroy
    if @visitor_entry
      @visitor_entry.destroy
      render_success({}, 'Visitor entry deleted successfully')
    else
      render_error('Visitor entry not found', :not_found)
    end
  end

  private

  def set_workspace
    @workspace = Workspace.find_by(id: params[:workspace_id])
    render_error('Workspace not found', :not_found) unless @workspace
  end

  def set_visitor_entry
    @visitor_entry = @workspace.visitor_entries.find_by(id: params[:id])
  end

  def visitor_entry_params
    params.require(:visitor_entry).permit(:name, :person_to_visit_name, :workspace_id, :phone_number, :email, :purpose, :photo)
  end

  def authorize_floor_user!
    unless current_user&.role == 'floor_user'
      render_error('Forbidden: Only floor users allowed', :forbidden)
    end
  end

  def visitor_entry_response(visitor_entry)
    {
      id: visitor_entry.id,
      name: visitor_entry.name,
      person_to_visit_name: visitor_entry.person_to_visit_name,
      workspace_id: visitor_entry.workspace_id,
      phone_number: visitor_entry.phone_number,
      email: visitor_entry.email,
      purpose: visitor_entry.purpose,
      photo_url: PhotoUploadService.photo_url(visitor_entry),
      photo_attached: PhotoUploadService.photo_attached?(visitor_entry),
      created_at: visitor_entry.created_at,
      updated_at: visitor_entry.updated_at
    }
  end
end 