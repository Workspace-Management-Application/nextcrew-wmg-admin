class Admin::VisitorEntriesController < Admin::BaseController
  before_action :set_visitor_entry, only: [:show, :edit, :update, :destroy]

  def index
    @search = params[:search]
    @visitor_entries = VisitorEntry.includes(:workspace)
    
    # Search functionality
    if @search.present?
      @visitor_entries = @visitor_entries.joins(:workspace).where(
        "visitor_entries.name ILIKE ? OR visitor_entries.email ILIKE ? OR visitor_entries.phone_number ILIKE ? OR visitor_entries.person_to_visit_name ILIKE ? OR visitor_entries.purpose ILIKE ? OR workspaces.name ILIKE ?",
        "%#{@search}%", "%#{@search}%", "%#{@search}%", "%#{@search}%", "%#{@search}%", "%#{@search}%"
      )
    end
    
    # Filter by workspace if specified
    if params[:workspace_id].present?
      @visitor_entries = @visitor_entries.where(workspace_id: params[:workspace_id])
    end
    
    # Filter by date range if specified
    if params[:date_from].present?
      @visitor_entries = @visitor_entries.where("created_at >= ?", Date.parse(params[:date_from]).beginning_of_day)
    end
    
    if params[:date_to].present?
      @visitor_entries = @visitor_entries.where("created_at <= ?", Date.parse(params[:date_to]).end_of_day)
    end
    
    # Order by created_at (newest first)
    @visitor_entries = @visitor_entries.order(created_at: :desc)
    
    # Pagination
    @visitor_entries = @visitor_entries.page(params[:page]).per(25)
    
    # For workspace filter dropdown
    @workspaces = Workspace.order(:name)
  end

  def show
  end

  def new
    @visitor_entry = VisitorEntry.new
    @workspaces = Workspace.order(:name)
  end

  def create
    @visitor_entry = VisitorEntry.new(visitor_entry_params)
    
    if @visitor_entry.save
      redirect_to admin_visitor_entries_path, notice: 'Visitor entry was successfully created.'
    else
      render :new
    end
  end

  def edit
    @workspaces = Workspace.order(:name)
  end

  def update
    if @visitor_entry.update(visitor_entry_params)
      redirect_to admin_visitor_entries_path, notice: 'Visitor entry was successfully updated.'
    else
      render :edit
    end
  end

  def destroy
    @visitor_entry.destroy
    redirect_to admin_visitor_entries_path, notice: 'Visitor entry was successfully deleted.'
  end

  private

  def set_visitor_entry
    @visitor_entry = VisitorEntry.find(params[:id])
  end

  def visitor_entry_params
    params.require(:visitor_entry).permit(:name, :email, :phone_number, :person_to_visit_name, :purpose, :workspace_id, :photo)
  end
end 