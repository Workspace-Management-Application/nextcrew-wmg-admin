class Api::VisitorEntriesController < Api::BaseController
  before_action :set_workspace
  before_action :set_visitor_entry, only: [:show, :update, :destroy]
  before_action :authorize_floor_user!

  # GET /api/workspaces/:workspace_id/visitor_entries
  def index
    visitor_entries = @workspace.visitor_entries
    render_success(visitor_entries)
  end

  # GET /api/workspaces/:workspace_id/visitor_entries/:id
  def show
    if @visitor_entry
      render_success(@visitor_entry)
    else
      render_error('Visitor entry not found', :not_found)
    end
  end

  # POST /api/workspaces/:workspace_id/visitor_entries
  def create
    visitor_entry = @workspace.visitor_entries.new(visitor_entry_params.except(:photo))
    if params[:photo].present?
      photo_url = S3Uploader.upload(params[:photo], folder: 'visitor_photos')
      visitor_entry.photo = photo_url
    end
    if visitor_entry.save
      render_success(visitor_entry, 'Visitor entry created successfully', :created)
    else
      render_error(visitor_entry.errors.full_messages.join(', '))
    end
  end

  # PATCH/PUT /api/workspaces/:workspace_id/visitor_entries/:id
  def update
    if @visitor_entry
      if params[:photo].present?
        photo_url = S3Uploader.upload(params[:photo], folder: 'visitor_photos')
        @visitor_entry.photo = photo_url
      end
      if @visitor_entry.update(visitor_entry_params.except(:photo))
        render_success(@visitor_entry, 'Visitor entry updated successfully')
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
    params.require(:visitor_entry).permit(:name, :workspace_id, :phone_number, :email, :purpose, :photo)
  end

  def authorize_floor_user!
    unless current_user&.role == 'floor_user'
      render_error('Forbidden: Only floor users allowed', :forbidden)
    end
  end
end 