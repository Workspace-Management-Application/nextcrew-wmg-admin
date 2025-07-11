class Admin::OfficeEnquiriesController < Admin::BaseController
  before_action :set_office_enquiry, only: [:show, :edit, :update, :destroy]

  def index
    @search = params[:search]
    workspace_ids = current_user.workspaces.pluck(:id)
    @office_enquiries = OfficeEnquiry.includes(:workspace).where(workspace_id: workspace_ids)
  
    
    # Search functionality
    if @search.present?
      @office_enquiries = @office_enquiries.where(
        "enquirer_name ILIKE ? OR email ILIKE ? OR phone_number ILIKE ? OR company_name ILIKE ? OR workspaces.name ILIKE ?",
        "%#{@search}%", "%#{@search}%", "%#{@search}%", "%#{@search}%", "%#{@search}%"
      ).joins(:workspace)
    end
    
    # Filter by workspace if specified
    if params[:workspace_id].present?
      @office_enquiries = @office_enquiries.where(workspace_id: params[:workspace_id])
    end
    
    # Filter by date range if specified
    if params[:date_from].present?
      @office_enquiries = @office_enquiries.where("created_at >= ?", Date.parse(params[:date_from]).beginning_of_day)
    end
    
    if params[:date_to].present?
      @office_enquiries = @office_enquiries.where("created_at <= ?", Date.parse(params[:date_to]).end_of_day)
    end
    
    # Order by created_at (newest first)
    @office_enquiries = @office_enquiries.order(created_at: :desc)
    
    # Pagination
    @office_enquiries = @office_enquiries.page(params[:page]).per(25)
    
    # For workspace filter dropdown
    @workspaces = current_user.workspaces
  end

  def show
  end

  def new
    @office_enquiry = OfficeEnquiry.new
    @workspaces = current_user.workspaces.order(:name)
    workspace_ids = @workspaces.pluck(:id)
    @workspace_types = WorkspaceType.joins(:workspaces).where(workspaces: { id: workspace_ids }).distinct.order(:name)
  end

  def create
    @office_enquiry = OfficeEnquiry.new(office_enquiry_params)
    
    if @office_enquiry.save
      redirect_to admin_office_enquiries_path, notice: 'Office enquiry was successfully created.'
    else
      render :new
    end
  end

  def edit
    @workspaces = current_user.workspaces.order(:name)
    workspace_ids = @workspaces.pluck(:id)
    @workspace_types = WorkspaceType.joins(:workspaces).where(workspaces: { id: workspace_ids }).distinct.order(:name)
  end

  def update
    if @office_enquiry.update(office_enquiry_params)
      redirect_to admin_office_enquiries_path, notice: 'Office enquiry was successfully updated.'
    else
      render :edit
    end
  end

  def destroy
    @office_enquiry.destroy
    redirect_to admin_office_enquiries_path, notice: 'Office enquiry was successfully deleted.'
  end

  private

  def set_office_enquiry
    @office_enquiry = OfficeEnquiry.find(params[:id])
  end

  def office_enquiry_params
    params.require(:office_enquiry).permit(:enquirer_name, :email, :phone_number, :company_name, :workspace_id, :no_of_seats, workspace_type_ids: [])
  end
end 