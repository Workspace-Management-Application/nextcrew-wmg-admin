class Admin::DayPassesController < Admin::BaseController
  before_action :set_day_pass, only: [ :show, :edit, :update, :destroy ]
  before_action :set_workspaces, only: [ :index, :new, :create, :edit, :update ]

  def index
    @day_passes = DayPass.includes(:workspace)

    # Search functionality
    if params[:search].present?
      search_term = "%#{params[:search]}%"
      @day_passes = @day_passes.where(
        "name ILIKE ? OR email ILIKE ? OR phone_number ILIKE ? OR company_name ILIKE ?",
        search_term, search_term, search_term, search_term
      )
    end

    # Filter by workspace
    if params[:workspace_id].present?
      @day_passes = @day_passes.where(workspace_id: params[:workspace_id])
    end

    # Filter by date
    if params[:date].present?
      date = Date.parse(params[:date])
      @day_passes = @day_passes.where(pass_date: date)
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
    @day_pass.destroy
    redirect_to admin_day_passes_path, notice: "Day pass was successfully deleted."
  end

  private

  def set_day_pass
    @day_pass = DayPass.find(params[:id])
  end

  def set_workspaces
    @workspaces = Workspace.all.order(:name)
  end

  def day_pass_params
    params.require(:day_pass).permit(:name, :email, :phone_number, :pass_date, :company_name, :workspace_id, :photo, :id_proof)
  end
end
