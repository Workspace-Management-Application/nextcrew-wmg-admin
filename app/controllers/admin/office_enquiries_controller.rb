class Admin::OfficeEnquiriesController < Admin::BaseController
  before_action :set_office_enquiry, only: [:show, :edit, :update, :destroy]

  def index
    @search = params[:search]
    office_enquiries = filtered_office_enquiries

    # For workspace filter dropdown
    @workspaces = current_user.workspaces

    respond_to do |format|
      format.html do
        @office_enquiries = office_enquiries.page(params[:page]).per(25)
      end
      format.csv do
        send_data generate_office_enquiries_csv(office_enquiries),
                  filename: "office_enquiries_#{Time.current.strftime('%Y%m%d_%H%M%S')}.csv",
                  type: "text/csv"
      end
    end
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

  def filtered_office_enquiries
    workspace_ids = current_user.workspaces.pluck(:id)
    office_enquiries = OfficeEnquiry.includes(:workspace, :workspace_types).where(workspace_id: workspace_ids)

    # Search functionality
    if @search.present?
      office_enquiries = office_enquiries.joins(:workspace).where(
        "office_enquiries.enquirer_name ILIKE ? OR office_enquiries.email ILIKE ? OR office_enquiries.phone_number ILIKE ? OR office_enquiries.company_name ILIKE ? OR workspaces.name ILIKE ?",
        "%#{@search}%", "%#{@search}%", "%#{@search}%", "%#{@search}%", "%#{@search}%"
      )
    end

    # Filter by workspace if specified
    if params[:workspace_id].present?
      office_enquiries = office_enquiries.where(workspace_id: params[:workspace_id])
    end

    # Filter by date range if specified
    if params[:date_from].present?
      office_enquiries = office_enquiries.where("office_enquiries.created_at >= ?", Date.parse(params[:date_from]).beginning_of_day)
    end

    if params[:date_to].present?
      office_enquiries = office_enquiries.where("office_enquiries.created_at <= ?", Date.parse(params[:date_to]).end_of_day)
    end

    office_enquiries.order(created_at: :desc)
  end

  def generate_office_enquiries_csv(office_enquiries)
    require "csv"

    CSV.generate do |csv|
      csv << [
        "ID",
        "Enquirer Name",
        "Email",
        "Phone Number",
        "Company Name",
        "Workspace Types",
        "No. of Seats",
        "Workspace",
        "Enquiry Made At",
        "Updated At"
      ]

      office_enquiries.each do |enquiry|
        csv << [
          enquiry.id,
          enquiry.enquirer_name,
          enquiry.email,
          enquiry.phone_number,
          enquiry.company_name,
          enquiry.workspace_types.map(&:name).join(", "),
          enquiry.no_of_seats,
          enquiry.workspace&.name,
          enquiry.created_at.strftime("%B %d, %Y %I:%M %p"),
          enquiry.updated_at.strftime("%B %d, %Y %I:%M %p")
        ]
      end
    end
  end

  def set_office_enquiry
    @office_enquiry = OfficeEnquiry.find(params[:id])
  end

  def office_enquiry_params
    params.require(:office_enquiry).permit(:enquirer_name, :email, :phone_number, :company_name, :workspace_id, :no_of_seats, workspace_type_ids: [])
  end
end 
