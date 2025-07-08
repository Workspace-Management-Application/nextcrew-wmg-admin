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
    
    # Create CSV content
    csv_data = CSV.generate do |csv|
      # Header row
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
        'Total Exceeded Hours per Day',
        'Total Exceeded Hours per Month',
        'Total Bookings in Period',
        'Total Meeting Hours in Period'
      ]
      
      # Get companies based on filters
      companies = Company.all
      companies = companies.joins(:workspaces).where(workspaces: { id: workspace_id }) if workspace_id.present? && workspace_id != 'all'
      companies = companies.where(id: company_id) if company_id.present? && company_id != 'all'

      companies.each do |company|
        # Calculate exceeded hours
        daily_exceeded_hours = calculate_daily_exceeded_hours(company, start_date, end_date)
        monthly_exceeded_hours = calculate_monthly_exceeded_hours(company, start_date, end_date)
        total_bookings = calculate_total_bookings(company, start_date, end_date)
        total_hours = calculate_total_hours(company, start_date, end_date)

        # Add data row
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
          daily_exceeded_hours,
          monthly_exceeded_hours,
          total_bookings,
          total_hours
        ]
      end
    end
    
    # Return the CSV data
    csv_data
  end

  def calculate_daily_exceeded_hours(company, start_date, end_date)
    return 0 unless company.meeting_time_limit_per_day.present?

    total_exceeded = 0
    (start_date..end_date).each do |date|
      daily_usage = Booking.joins(user: :companies)
                          .where(companies: { id: company.id })
                          .where('DATE(bookings.start_time) = ?', date)
                          .sum('EXTRACT(EPOCH FROM (bookings.end_time - bookings.start_time)) / 3600')
      binding.pry if company.id ==3 
      daily_limit_hours = company.meeting_time_limit_per_day / 60.0
      exceeded = [daily_usage - daily_limit_hours, 0].max
      total_exceeded += exceeded
    end
    
    total_exceeded.round(2)
  end

  def calculate_monthly_exceeded_hours(company, start_date, end_date)
    return 0 unless company.meeting_time_limit_per_month.present?

    monthly_usage = Booking.joins(user: :companies)
                          .where(companies: { id: company.id })
                          .where('bookings.start_time >= ? AND bookings.start_time <= ?', start_date, end_date)
                          .sum('EXTRACT(EPOCH FROM (bookings.end_time - bookings.start_time)) / 3600')
    
    monthly_limit_hours = company.meeting_time_limit_per_month
    [monthly_usage - monthly_limit_hours, 0].max.round(2)
  end

  def calculate_total_bookings(company, start_date, end_date)
    Booking.joins(user: :companies)
           .where(companies: { id: company.id })
           .where('bookings.start_time >= ? AND bookings.start_time <= ?', start_date, end_date)
           .count
  end

  def calculate_total_hours(company, start_date, end_date)
    Booking.joins(user: :companies)
           .where(companies: { id: company.id })
           .where('bookings.start_time >= ? AND bookings.start_time <= ?', start_date, end_date)
           .sum('EXTRACT(EPOCH FROM (bookings.end_time - bookings.start_time)) / 3600')
           .round(2)
  end
end 