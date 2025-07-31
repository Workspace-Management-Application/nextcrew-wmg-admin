class Admin::DayPassesController < Admin::BaseController
  before_action :set_day_pass, only: [ :show, :edit, :update, :destroy ]
  before_action :set_workspaces, only: [ :index, :new, :create, :edit, :update ]

  def index
    # Filter day passes by admin's workspace access
    @day_passes = if current_user.super_admin?
                    DayPass.includes(:workspace)
    else
                    DayPass.includes(:workspace).where(workspace: current_user.workspaces)
    end

    # Search functionality using scope
    @day_passes = @day_passes.search_by_term(params[:search])

    # Filter by workspace
    if params[:workspace_id].present?
      @day_passes = @day_passes.where(workspace_id: params[:workspace_id])
    end

    # Filter by date
    if params[:date].present?
      begin
        date = Date.parse(params[:date])
        @day_passes = @day_passes.where(pass_date: date)
      rescue Date::Error
        flash.now[:alert] = "Invalid date format"
      end
    end

    # Order by most recent first
    @day_passes = @day_passes.order(created_at: :desc)

    # Pagination
    @day_passes = @day_passes.page(params[:page]).per(20)
  end

  def show
  end

  def new
    @day_pass = DayPass.new
  end

  def create
    @day_pass = DayPass.new(day_pass_params)

    if @day_pass.save
      redirect_to admin_day_pass_path(@day_pass), notice: "Day pass was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @day_pass.update(day_pass_params)
      redirect_to admin_day_pass_path(@day_pass), notice: "Day pass was successfully updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    begin
      @day_pass.destroy!
      redirect_to admin_day_passes_path, notice: "Day pass was successfully deleted."
    rescue ActiveRecord::RecordNotDestroyed => e
      redirect_to admin_day_passes_path, alert: "Failed to delete day pass: #{e.message}"
    rescue ActiveRecord::RecordNotFound
      redirect_to admin_day_passes_path, alert: "Day pass not found."
    rescue StandardError => e
      Rails.logger.error "Error deleting day pass #{@day_pass.id}: #{e.message}"
      redirect_to admin_day_passes_path, alert: "An error occurred while deleting the day pass."
    end
  end

  private

  def set_day_pass
    @day_pass = DayPass.find(params[:id])
  end

  def set_workspaces
    # Super admins can see all workspaces, regular admins only see their assigned workspaces
    if current_user.super_admin?
      @workspaces = Workspace.all.order(:name)
    else
      @workspaces = current_user.workspaces.order(:name)
    end
  end

  def day_pass_params
    params.require(:day_pass).permit(:name, :email, :phone_number, :pass_date, :company_name, :workspace_id, :photo, :id_proof)
  end
end
