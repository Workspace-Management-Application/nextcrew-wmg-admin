class Booking < ApplicationRecord
  belongs_to :user
  belongs_to :room

  enum :status, { confirmed: 'confirmed', cancelled: 'cancelled' }, default: :confirmed

  validates :phone_number, :user_id, :room_id, :start_time, :end_time, :status, presence: true
  validate :no_time_overlap_for_room

  private

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
end
