class Admin::CompaniesController < Admin::BaseController
  before_action :set_company, only: [:show, :edit, :update, :destroy]

  def index
    @companies = Company.all
  end

  def show
    @company_users = @company.users
    @usage_analytics = calculate_usage_analytics(@company)
  end

  def new
    @company = Company.new
  end

  def create
    @company = Company.new(company_params)
    
    if @company.save
      redirect_to admin_companies_path, notice: 'Company was successfully created.'
    else
      render :new
    end
  end

  def edit
  end

  def update
    if @company.update(company_params)
      redirect_to admin_company_path(@company), notice: 'Company was successfully updated.'
    else
      render :edit
    end
  end

  def destroy
    @company.destroy
    redirect_to admin_companies_path, notice: 'Company was successfully deleted.'
  end

  private

  def set_company
    @company = Company.find(params[:id])
  end

  def company_params
    params.require(:company).permit(:name, :email, :phone, :address, :contact_person)
  end

  def calculate_usage_analytics(company)
    {
      total_users: company.users.count,
      total_bookings: company.users.joins(:bookings).count,
      this_month_bookings: company.users.joins(:bookings).where(bookings: { created_at: Date.current.beginning_of_month..Date.current.end_of_month }).count,
      active_users: company.users.joins(:bookings).where(bookings: { created_at: 30.days.ago..Date.current }).distinct.count
    }
  end
end
