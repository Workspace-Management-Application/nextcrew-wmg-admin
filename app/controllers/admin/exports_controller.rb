class Admin::ExportsController < Admin::BaseController
  def index
    @workspaces = allowed_workspaces
    @companies = Company.none
  end

  def get_companies_by_workspace
    workspace = find_allowed_workspace(params[:workspace_id])

    if workspace
      companies = companies_for_workspace(workspace)
      render json: companies.map { |c| { id: c.id, name: c.name } }
    elsif params[:workspace_id].present?
      render json: [], status: :forbidden
    else
      render json: []
    end
  end

  def export_company_details
    workspace_id = params[:workspace_id]
    workspace = find_allowed_workspace(params[:workspace_id])
    company_id = params[:company_id]
    start_date = params[:start_date].present? ? Date.parse(params[:start_date]).beginning_of_day : Date.current.beginning_of_month.beginning_of_day
    end_date = params[:end_date].present? ? Date.parse(params[:end_date]).end_of_day : Date.current.end_of_month.end_of_day

    # Validate required parameters
    unless workspace_id.present?
      redirect_to admin_exports_path, alert: "Please select a workspace."
      return
    end

    unless workspace
      redirect_to admin_exports_path, alert: "You are not authorized to export this workspace."
      return
    end

    if company_id.present? && !companies_for_workspace(workspace).exists?(id: company_id)
      redirect_to admin_exports_path, alert: "Selected company is not available for this workspace."
      return
    end

    # Generate CSV file
    csv_data = generate_company_details_csv(workspace, company_id, start_date, end_date)

    # Send file as download
    send_data csv_data,
              filename: "company_details_#{Date.current.strftime('%Y%m%d')}.csv",
              type: "text/csv"
  end

  private

  def allowed_workspaces
    if current_user.super_admin?
      Workspace.all.order(:name)
    else
      current_user.workspaces.order(:name)
    end
  end

  def find_allowed_workspace(workspace_id)
    return if workspace_id.blank?

    allowed_workspaces.find_by(id: workspace_id)
  end

  def companies_for_workspace(workspace)
    Company.joins(:workspaces).where(workspaces: { id: workspace.id }).distinct.order(:name)
  end

  def generate_company_details_csv(workspace, company_id, start_date, end_date)
    require "csv"
    companies = companies_for_workspace(workspace)
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

        exceed_rows = build_booking_exceed_rows(company, start_date, end_date)
        exceed_minutes = exceed_rows.sum { |row| row[:exceed_time] }
        total_bookings = exceed_rows.count { |row| row[:counts_toward_usage] }
        total_minutes = exceed_rows.sum { |row| row[:usage_minutes] }

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
          "Exceed Time Reason",
          "Status",
          "Created At"
        ]

        total_duration = 0
        total_exceed_time = 0

        exceed_rows.each do |row|
          booking = row[:booking]
          duration_minutes = row[:duration_minutes]
          exceed_time = row[:exceed_time]
          exceed_reason = row[:exceed_reason]

          total_duration += row[:usage_minutes]
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
            exceed_reason,
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
          "",
          ""
        ]

        csv << []
        csv << [ "EXCEED CHARGES - #{company.name}" ]
        csv << [
          "Room",
          "Exceed (min)",
          "Rate/hr (₹)",
          "Rate/min (₹)",
          "Amount (₹)"
        ]

        exceed_charge_rows = build_exceed_charge_rows(exceed_rows)
        if exceed_charge_rows.any?
          total_charge_minutes = 0
          total_charge_amount = 0.0

          exceed_charge_rows.each do |charge_row|
            total_charge_minutes += charge_row[:exceeded_minutes]
            total_charge_amount += charge_row[:amount]

            csv << [
              charge_row[:room_name],
              charge_row[:exceeded_minutes],
              charge_row[:hourly_rate],
              format_amount(charge_row[:rate_per_minute]),
              format_amount(charge_row[:amount])
            ]
          end

          csv << [
            "TOTAL",
            "",
            "",
            "",
            format_amount(total_charge_amount)
          ]
        else
          csv << [ "No exceeded time charges", "", "", "", "" ]
        end

        csv << []
        csv << []
      end
    end
    csv_data
  end

  def build_booking_exceed_rows(company, start_date, end_date)
    company.bookings.confirmed.includes(:room)
           .where("bookings.start_time >= ? AND bookings.start_time <= ?", start_date, end_date)
           .order(:created_at, :id)
           .map do |booking|
             duration_minutes = booking_duration_minutes(booking)
             exceed_result = calculate_exceed_result(booking, duration_minutes)
             {
               booking: booking,
               duration_minutes: duration_minutes,
               usage_minutes: duration_minutes,
               exceed_time: exceed_result[:minutes],
               exceed_reason: exceed_result[:reason],
               counts_toward_usage: true
             }
           end
  end

  def build_exceed_charge_rows(exceed_rows)
    exceed_rows.each_with_object({}) do |row, charges|
      next unless row[:exceed_time].positive?

      room = row[:booking].room
      charges[room.id] ||= {
        room_name: room.name,
        hourly_rate: room.price_per_hour.to_i,
        rate_per_minute: room.price_per_hour.to_i / 60.0,
        exceeded_minutes: 0,
        amount: 0.0
      }
      charges[room.id][:exceeded_minutes] += row[:exceed_time]
      charges[room.id][:amount] += (row[:exceed_time] / 60.0) * room.price_per_hour.to_i
    end.values.sort_by { |row| row[:room_name] }
  end

  def calculate_exceed_result(booking, duration_minutes)
    return { minutes: 0, reason: "" } unless booking.start_time.present? && booking.end_time.present?

    results = [
      {
        minutes: threshold_exceed(previous_daily_minutes(booking), booking.company.meeting_time_limit_per_day, duration_minutes),
        reason: "Daily time exceeded"
      },
      {
        minutes: threshold_exceed(previous_monthly_minutes(booking), booking.company.meeting_time_limit_per_month, duration_minutes),
        reason: "Monthly time exceeded"
      },
      { minutes: meeting_count_exceed(booking, duration_minutes), reason: "Meetings per day exceeded" }
    ]
    result = results.max_by { |item| item[:minutes] }

    result[:minutes].positive? ? result : { minutes: 0, reason: "" }
  end

  def threshold_exceed(previous_usage, limit, duration_minutes)
    previous_usage = previous_usage.to_i
    limit = limit.to_i

    if previous_usage >= limit
      duration_minutes
    else
      [ previous_usage + duration_minutes - limit, 0 ].max
    end
  end

  def meeting_count_exceed(booking, duration_minutes)
    limit = booking.company.no_of_meeting_per_day.to_i
    previous_count = previous_daily_booking_count(booking)

    previous_count >= limit ? duration_minutes : 0
  end

  def previous_daily_minutes(booking)
    previous_confirmed_bookings(booking)
      .where("start_time >= ? AND start_time <= ?", booking.start_time.beginning_of_day, booking.start_time.end_of_day)
      .sum("EXTRACT(EPOCH FROM (end_time - start_time)) / 60")
  end

  def previous_monthly_minutes(booking)
    previous_confirmed_bookings(booking)
      .where("start_time >= ? AND start_time < ?", booking.start_time.beginning_of_month, booking.start_time.next_month.beginning_of_month)
      .sum("EXTRACT(EPOCH FROM (end_time - start_time)) / 60")
  end

  def previous_daily_booking_count(booking)
    previous_confirmed_bookings(booking)
      .where("start_time >= ? AND start_time <= ?", booking.start_time.beginning_of_day, booking.start_time.end_of_day)
      .count
  end

  def previous_confirmed_bookings(booking)
    booking.company.bookings.confirmed
           .where("created_at < ? OR (created_at = ? AND id < ?)", booking.created_at, booking.created_at, booking.id)
  end

  def booking_duration_minutes(booking)
    ((booking.end_time - booking.start_time) / 60).to_i
  end

  def format_amount(amount)
    format("%.2f", amount)
  end
end
