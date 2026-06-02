class Booking < ApplicationRecord
  attr_accessor :acting_user
  belongs_to :company
  belongs_to :room

  enum :status, { confirmed: 'confirmed', cancelled: 'cancelled' }, default: :confirmed

  validates :phone_number, :company_id, :room_id, :start_time, :end_time, :status, presence: true
  validates :phone_number, format: { with: /\A[1-9][0-9]{9}\z/, message: "must be 10 digits and not start with zero" }
  validate :start_and_end_time_validity
  validate :no_time_overlap_for_room
  validate :check_meeting_duration_limits
  validate :check_company_time_slot_overlap
  validate :company_room_association_exists
  validate :check_user_booking_time_restrictions
  validate :check_user_forward_booking_restrictions
  validate :start_time_cannot_be_in_past_for_user_roles

  after_commit :check_monthly_meeting_time_limit, on: :create
  after_commit :check_daily_meeting_time_limit, on: :create

  def duration_minutes
    return 0 if start_time.blank? || end_time.blank?
    ((end_time - start_time) / 60).to_i
  end

  def duration_hours
    return 0 if start_time.blank? || end_time.blank?
    ((end_time - start_time) / 3600).to_f
  end

  def monthly_usage_minutes
    return 0 if company.blank? || start_time.blank?
    
    booking_month = start_time.beginning_of_month
    Booking.joins(:company)
           .where(companies: { id: company.id })
           .where('bookings.start_time >= ? AND bookings.start_time < ?', booking_month, booking_month.next_month)
           .where.not(id: id) # Exclude current booking if updating
           .sum('EXTRACT(EPOCH FROM (bookings.end_time - bookings.start_time)) / 60')
  end

  def daily_usage_minutes
    return 0 if company.blank? || start_time.blank?
    
    booking_date = start_time.to_date
    Booking.joins(:company)
           .where(companies: { id: company.id })
           .where('DATE(bookings.start_time) = ?', booking_date)
           .where.not(id: id) # Exclude current booking if updating
           .sum('EXTRACT(EPOCH FROM (bookings.end_time - bookings.start_time)) / 60')
  end

  def monthly_limit_exceeded?
    return false if company.blank?
    (monthly_usage_minutes + duration_minutes) > company.meeting_time_limit_per_month
  end

  def daily_limit_exceeded?
    return false if company.blank?
    (daily_usage_minutes + duration_minutes) > company.meeting_time_limit_per_day
  end

  def should_send_monthly_limit_notification?
    return false unless monthly_limit_exceeded?
    return false if company.blank?
    
    # Only send notification for new bookings, not updates
    true
  end

  def should_send_daily_limit_notification?
    return false unless daily_limit_exceeded?
    return false if company.blank?
    
    # Only send notification for new bookings, not updates
    true
  end

  # Helper method to format minutes into hours and minutes for display
  def format_minutes_to_hours_and_minutes(minutes)
    return "0 minutes" if minutes.nil? || minutes <= 0
    
    hours = minutes / 60
    remaining_minutes = minutes % 60
    
    if hours > 0 && remaining_minutes > 1
      "#{hours} hour#{hours > 1 ? 's' : ''} #{remaining_minutes} minute#{remaining_minutes > 1 ? 's' : ''}"
    elsif hours > 0
      "#{hours} hour#{hours > 1 ? 's' : ''}"
    else
      "#{remaining_minutes} minute#{remaining_minutes > 1 ? 's' : ''}"
    end
  end

  # Helper method to check if user can override company restrictions
  def can_override_company_restrictions?
    acting_user&.admin? || acting_user&.super_admin?
  end

  def completed?
    end_time.present? && end_time < Time.current
  end

  def editable?
    !cancelled?
  end

  # Method to get all validation errors as an array
  def all_validation_errors
    # Run validations if not already run
    valid? unless errors.any?
    
    # Collect all error messages
    error_messages = []
    
    errors.each do |error|
      if error.attribute == :base
        error_messages << error.message
      else
        error_messages << "#{error.attribute.to_s.humanize} #{error.message}"
      end
    end
    
    error_messages
  end

  # Helper method to get overlapping company bookings
  def overlapping_company_bookings
    return Booking.none if company.blank? || start_time.blank? || end_time.blank? || room.blank? || room.workspace_id.blank?

    Booking.joins(:company, room: :workspace)
           .where(companies: { id: company.id })
           .where(rooms: { workspace_id: room.workspace_id }) # Only same workspace
           .where('bookings.start_time < ? AND bookings.end_time > ?', end_time, start_time)
           .where.not(id: id) # Exclude current booking if updating
           .includes(:company, :room, room: :workspace)
  end

  # Helper method to check if company has time slot conflicts
  def company_has_time_slot_conflicts?
    return false if can_override_company_restrictions?
    overlapping_company_bookings.exists?
  end

  private

  def start_time_cannot_be_in_past_for_user_roles
    return if can_override_company_restrictions?
    return if start_time.blank?
    if (acting_user&.user? || acting_user&.floor_user?) && start_time < Time.current
      errors.add(:start_time, "Start time cannot be past from the current Time")
    end
  end

  def no_time_overlap_for_room
    return if start_time.blank? || end_time.blank? || room_id.blank?

    overlapping = Booking.where(room_id: room_id)
                        .where.not(id: id)
                        .where('DATE(start_time) = ?', start_time.to_date)
                        .where('start_time < ? AND end_time > ?', end_time, start_time)
    if overlapping.exists?
      errors.add(:base, 'Room Already Booked in the entered given slot')
    end
  end

  def check_meeting_duration_limits
    return if company.blank? || start_time.blank? || end_time.blank?
    return unless acting_user&.user? || acting_user&.floor_user?
    return if can_override_company_restrictions?
    
    # Check if duration is within company limits
    if duration_minutes < company.minimum_minutes_meeting_limit
      errors.add(:base, "Meeting duration must be at least #{company.minimum_minutes_meeting_limit} minutes. Your booking is for #{duration_minutes} minutes.")
    end
    if duration_minutes > company.max_minutes_meeting_limit
      errors.add(:base, "Meeting duration cannot exceed #{company.max_minutes_meeting_limit} minutes. Your booking is for #{duration_minutes} minutes.")
    end
  end

  def check_company_time_slot_overlap
    return if company.blank? || start_time.blank? || end_time.blank?
    return if can_override_company_restrictions?
    return if company.parallel_booking?
    
    # Check if the company has any other bookings in the same time slot
    if company_has_time_slot_conflicts?
      overlapping_details = overlapping_company_bookings.map do |booking|
        "#{booking.company.name} - #{booking.room.name} (#{booking.room.workspace.name})"
      end.join(', ')
      
      errors.add(:base, "Your company already has a booking in this time slot: #{overlapping_details}. Please contact an administrator if you need to make this booking.")
    end
  end

  def start_and_end_time_validity
    return if start_time.blank? || end_time.blank?

    if start_time == end_time
      errors.add(:end_time, "cannot be the same as start time")
    end
    if end_time < start_time
      errors.add(:end_time, "cannot be before start time")
    end
  end

  def company_room_association_exists
    return if company.blank? || room.blank?
    unless CompanyRoom.exists?(company_id: company.id, room_id: room.id)
      errors.add(:room, "is not associated with your company. Please select a valid room.")
    end
  end

  def check_monthly_meeting_time_limit
    if should_send_monthly_limit_notification?
      begin
        BookingMailer.monthly_limit_exceeded_notification(self).deliver_now
      rescue => e
        Rails.logger.error "Failed to send monthly limit exceeded notification: #{e.message}"
      end
    end
  end

  def check_daily_meeting_time_limit
    if should_send_daily_limit_notification?
      begin
        BookingMailer.daily_limit_exceeded_notification(self).deliver_now
      rescue => e
        Rails.logger.error "Failed to send daily limit exceeded notification: #{e.message}"
      end
    end
  end

  def check_user_booking_time_restrictions
    return if company.blank? || start_time.blank? || end_time.blank?
    return unless acting_user&.user? || acting_user&.floor_user?
    return if can_override_company_restrictions?

    # Check if user has any existing bookings on the same date
    booking_date = start_time.to_date
    
    existing_bookings = Booking.where(room_id: room.id)
                              .where('DATE(start_time) = ?', booking_date)
                              .where.not(id: id) # Exclude current booking if updating
                              .order(:start_time)

    existing_bookings.each do |existing_booking|
      # Rule 1: Can't book before an existing booking's start time in the same room
      if start_time < existing_booking.start_time
        errors.add(:start_time, "You have already booking from before #{existing_booking.start_time.strftime('%I:%M %p')} to #{existing_booking.end_time.strftime('%I:%M %p')} in #{existing_booking.room.name}. You are only allow to make booking after #{existing_booking.end_time.strftime('%I:%M %p')}")
      end
    end
  end

  def check_user_forward_booking_restrictions
    return if company.blank? || start_time.blank? || end_time.blank?
    return unless acting_user&.user? || acting_user&.floor_user?
    return if can_override_company_restrictions?

    # Check if there are any existing bookings in the same room on the same date
    booking_date = start_time.to_date
    
    existing_bookings = Booking.where(room_id: room.id)
                              .where('DATE(start_time) = ?', booking_date)
                              .where.not(id: id) # Exclude current booking if updating
                              .order(:start_time)

    current_time = Time.current
    
    existing_bookings.each do |existing_booking|
      # Rule: Can't book a room starting after an existing booking's end time 
      # unless current time is at least 10 minutes before the existing booking ends
      if start_time >= existing_booking.end_time
        forward_booking_threshold = existing_booking.end_time - 10.minutes
        
        if current_time < forward_booking_threshold
          errors.add(:start_time, "cannot be booked for #{start_time.strftime('%I:%M %p')} because forward booking is only allowed after #{forward_booking_threshold.strftime('%I:%M %p')} (10 minutes before your existing booking ends at #{existing_booking.end_time.strftime('%I:%M %p')} in #{existing_booking.room.name})")
        end
      end
    end
  end


end
