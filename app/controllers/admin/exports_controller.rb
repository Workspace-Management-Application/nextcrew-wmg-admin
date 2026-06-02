class Admin::ExportsController < Admin::BaseController
  def index
    @workspaces = Workspace.all.order(:name)
    @companies = Company.all.order(:name)
  end

  def get_companies_by_workspace
    workspace_id = params[:workspace_id]

    if workspace_id.present?
      companies = Company.joins(:workspaces).where(workspaces: { id: workspace_id }).order(:name)
      render json: companies.map { |c| { id: c.id, name: c.name } }
    else
      render json: []
    end
  end

  def export_company_details
    workspace_id = params[:workspace_id]
    company_id = params[:company_id]
    start_date = params[:start_date].present? ? Date.parse(params[:start_date]).beginning_of_day : Date.current.beginning_of_month.beginning_of_day
    end_date = params[:end_date].present? ? Date.parse(params[:end_date]).end_of_day : Date.current.end_of_month.end_of_day

    # Validate required parameters
    unless workspace_id.present?
      redirect_to admin_exports_path, alert: "Please select a workspace."
      return
    end

    # Generate CSV file
    csv_data = generate_company_details_csv(workspace_id, company_id, start_date, end_date)

    # Send file as download
    send_data csv_data,
              filename: "company_details_#{Date.current.strftime('%Y%m%d')}.csv",
              type: "text/csv"
  end

  private

  def generate_company_details_csv(workspace_id, company_id, start_date, end_date)
    require "csv"
    companies = Company.joins(:workspaces).where(workspaces: { id: workspace_id }).order(:name)
    companies = companies.where(id: company_id) if company_id.present?

    csv_data = CSV.generate do |csv|
      companies.each do |company|
        csv << [ "COMPANY DETAILS - #{company.name}" ]
        csv << [
          "Company Name",
          "Email",
          "Phone Number",
          "Address",
          "Cabin Number",
          "Number of Employees",
          "Meeting Time Limit per Month (minutes)",
          "Meeting Time Limit per Day (minutes)",
          "Number of Meetings per Day",
          "Minimum Meeting Duration (minutes)",
          "Maximum Meeting Duration (minutes)",
          "Status",
          "Total Exceed Minutes",
          "Total Bookings in Period",
          "Total Meeting Minutes in Period"
        ]

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

        # Add empty rows for spacing
        csv << []
        csv << []

        # Booking Details Section
        csv << [ "BOOKING DETAILS - #{company.name}" ]
        csv << [
          "Company Name",
          "Booker Name",
          "Phone Number",
          "Room Name",
          "Start Date",
          "Start Time",
          "End Time",
          "Duration (minutes)",
          "Exceed Time (minutes)",
          "Status",
          "Created At"
        ]

        bookings = company.bookings.includes(:room)
                          .where("bookings.start_time >= ? AND bookings.start_time <= ?", start_date, end_date)
                          .order("bookings.start_time ASC")

        total_duration = 0
        total_exceed_time = 0

        bookings.each do |booking|
          duration_minutes = ((booking.end_time - booking.start_time) / 60).to_i
          exceed_time = calculate_exceed_time(booking, company.meeting_time_limit_per_day.to_i)

          total_duration += duration_minutes
          total_exceed_time += exceed_time

          csv << [
            company.name,
            booking.booker_name,
            booking.phone_number,
            booking.room&.name || "N/A",
            booking.start_time.strftime("%d/%m/%Y"),
            booking.start_time.strftime("%H:%M"),
            booking.end_time.strftime("%H:%M"),
            duration_minutes,
            exceed_time,
            booking.status.to_s,
            booking.created_at.strftime("%d/%m/%Y %H:%M")
          ]
        end

        # Add summary row
        csv << []
        csv << [
          "TOTAL",
          "",
          "",
          "",
          "",
          "",
          "",
          total_duration,
          total_exceed_time,
          "",
          ""
        ]

        csv << []
        csv << []
      end
    end
    csv_data
  end

  def calculate_exceed_minutes(company, start_date, end_date)
    monthly_limit = company.meeting_time_limit_per_month.to_i
    daily_limit = company.meeting_time_limit_per_day.to_i
    bookings = company.bookings
                     .where("bookings.start_time >= ? AND bookings.start_time <= ?", start_date, end_date)
                     .order("bookings.start_time ASC")

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
        daily_exceed = [ daily_totals[date] - daily_limit, 0 ].max
        within_monthly = [ monthly_limit - monthly_used, 0 ].max
        monthly_exceed = [ minutes - within_monthly, 0 ].max
      end

      monthly_used += minutes
      monthly_used = [ monthly_used, monthly_limit ].min
      exceed = daily_exceed + monthly_exceed
      total_exceed += exceed
    end
    [ total_exceed, total_bookings, total_minutes ]
  end

  def calculate_exceed_time(booking, daily_limit)
    return 0 unless booking.start_time.present? && booking.end_time.present?

    minutes = ((booking.end_time - booking.start_time) / 60).to_i

    company = booking.company
    date = booking.start_time.to_date
    month_start = date.beginning_of_month
    month_end = date.end_of_month

    # Calculate total minutes used on this day before this booking
    previous_daily_bookings = company.bookings
                                    .where("start_time >= ? AND start_time < ?", date.beginning_of_day, booking.start_time)
                                    .sum("EXTRACT(EPOCH FROM (end_time - start_time)) / 60")

    # Calculate total minutes used in this month before this booking
    previous_monthly_bookings = company.bookings
                                      .where("start_time >= ? AND start_time < ?", month_start, booking.start_time)
                                      .sum("EXTRACT(EPOCH FROM (end_time - start_time)) / 60")

    # Get monthly limit
    monthly_limit = company.meeting_time_limit_per_month.to_i

    # Calculate total minutes including this booking
    total_daily_minutes = previous_daily_bookings + minutes
    total_monthly_minutes = previous_monthly_bookings + minutes

    # Calculate exceed time for this booking
    daily_exceed = 0
    monthly_exceed = 0

    # Check daily limit exceed
    if previous_daily_bookings >= daily_limit
      # Already exceeded daily limit, so this entire booking is excess for daily
      daily_exceed = minutes
    else
      # Check if this booking pushes us over the daily limit
      daily_exceed = [ total_daily_minutes - daily_limit, 0 ].max
    end

    # Check monthly limit exceed
    if previous_monthly_bookings >= monthly_limit
      # Already exceeded monthly limit, so this entire booking is excess for monthly
      monthly_exceed = minutes
    else
      # Check if this booking pushes us over the monthly limit
      monthly_exceed = [ total_monthly_minutes - monthly_limit, 0 ].max
    end

    # Return the maximum of daily and monthly exceed (whichever is higher)
    [ daily_exceed, monthly_exceed ].max
  end

  def generate_booking_details_csv(company, start_date, end_date)
    require "csv"
    daily_limit = company.meeting_time_limit_per_day.to_i
    bookings = company.bookings.where("bookings.start_time >= ? AND bookings.start_time <= ?", start_date, end_date).order("bookings.start_time ASC")
    daily_totals = Hash.new(0)

    csv_data = CSV.generate do |csv|
      csv << [
        "Room Name",
        "Start Date",
        "Start Time",
        "Duration (minutes)",
        "Exceed Time (minutes)",
        "Status",
        "Created At"
      ]
      total_exceed = 0
      bookings.each do |booking|
        date = booking.start_time.to_date
        minutes = ((booking.end_time - booking.start_time) / 60).to_i
        previous_total = daily_totals[date]
        # Calculate exceed for this booking only
        exceed = [ [ previous_total + minutes - daily_limit, 0 ].max - [ previous_total - daily_limit, 0 ].max, minutes ].min
        daily_totals[date] += minutes
        total_exceed += exceed
                 csv << [
           booking.room.try(:name) || booking.room_id,
           booking.start_time.strftime("%d/%m/%Y"),
           booking.start_time.strftime("%H:%M"),
           minutes,
           exceed,
           booking.status.to_s,
           booking.created_at.strftime("%d/%m/%Y %H:%M")
         ]
      end
      # Optionally, add a summary row for total exceed
      # csv << ['','','','Total Exceed', total_exceed]
    end
    csv_data
  end
end
