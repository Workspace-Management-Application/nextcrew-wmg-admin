class Room < ApplicationRecord
  def is_occupied?
    Booking.where(room_id: id, status: 'confirmed')
           .where('start_time <= ? AND end_time >= ?', Time.current, Time.current)
           .exists?
  end
end
