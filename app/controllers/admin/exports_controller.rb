class Admin::ExportsController < Admin::BaseController
  def index
    @workspaces = Workspace.all.order(:name)
    @companies = Company.all.order(:name)
  end

  def get_companies_by_workspace
    workspace_id = params[:workspace_id]
    
    if workspace_id == 'all'
      companies = Company.all.order(:name)
    else
      companies = Company.joins(:workspaces).where(workspaces: { id: workspace_id }).order(:name)
    end
    
    render json: companies.map { |c| { id: c.id, name: c.name } }
  end

  def export_company_details
    workspace_id = params[:workspace_id]
    company_id = params[:company_id]
    start_date = params[:start_date].present? ? Date.parse(params[:start_date]) : Date.current.beginning_of_month
    end_date = params[:end_date].present? ? Date.parse(params[:end_date]) : Date.current.end_of_month

    # Generate CSV file
    csv_data = generate_company_details_csv(workspace_id, company_id, start_date, end_date)
    
    # Send file as download
    send_data csv_data, 
              filename: "company_details_#{Date.current.strftime('%Y%m%d')}.csv",
              type: 'text/csv'
  end

  private

  def generate_company_details_csv(workspace_id, company_id, start_date, end_date)
    require 'csv'
    csv_data = CSV.generate do |csv|
      csv << [
        'Company Name',
        'Email',
        'Phone Number',
        'Address',
        'Cabin Number',
        'Number of Employees',
        'Meeting Time Limit per Month (minutes)',
        'Meeting Time Limit per Day (minutes)',
        'Number of Meetings per Day',
        'Minimum Meeting Duration (minutes)',
        'Maximum Meeting Duration (minutes)',
        'Status',
        'Total Exceed Minutes',
        'Total Bookings in Period',
        'Total Meeting Minutes in Period'
      ]

      companies = Company.all
      companies = companies.joins(:workspaces).where(workspaces: { id: workspace_id }) if workspace_id.present? && workspace_id != 'all'
      companies = companies.where(id: company_id) if company_id.present? && company_id != 'all'

      companies.each do |company|
        bookings = company.bookings.where('bookings.start_time >= ? AND bookings.start_time <= ?', start_date, end_date)
        Rails.logger.info "Company: #{company.id} Bookings count: #{bookings.count} Bookings: #{bookings.pluck(:id, :start_time, :end_time)}"
        exceed_minutes, total_bookings, total_minutes = calculate_exceed_minutes(company, start_date, end_date)
        csv << [
          company.name,
          company.email,
          company.phone_number,
          company.address,
          company.cabin_number,
          company.no_of_employee,
          company.meeting_time_limit_per_month,
          company.meeting_time_limit_per_day,
          company.no_of_meeting_per_day,
          company.minimum_minutes_meeting_limit,
          company.max_minutes_meeting_limit,
          company.status,
          exceed_minutes,
          total_bookings,
          total_minutes
        ]
      end
    end
    csv_data
  end

  def calculate_exceed_minutes(company, start_date, end_date)
    monthly_limit = company.meeting_time_limit_per_month.to_i
    daily_limit = company.meeting_time_limit_per_day.to_i
    bookings = company.bookings
                     .where('bookings.start_time >= ? AND bookings.start_time <= ?', start_date, end_date)
                     .order('bookings.start_time ASC')

    daily_totals = Hash.new(0)
    monthly_used = 0
    total_exceed = 0
    total_bookings = 0
    total_minutes = 0

    bookings.each do |booking|
      date = booking.start_time.to_date
      minutes = ((booking.end_time - booking.start_time) / 60).to_i
      daily_totals[date] += minutes
      total_bookings += 1
      total_minutes += minutes

      if monthly_used >= monthly_limit
        daily_exceed = 0
        monthly_exceed = minutes
      else
        daily_exceed = [daily_totals[date] - daily_limit, 0].max
        within_monthly = [monthly_limit - monthly_used, 0].max
        monthly_exceed = [minutes - within_monthly, 0].max
      end

      monthly_used += minutes
      monthly_used = [monthly_used, monthly_limit].min
      exceed = daily_exceed + monthly_exceed
      total_exceed += exceed
    end
    [total_exceed, total_bookings, total_minutes]
  end
end