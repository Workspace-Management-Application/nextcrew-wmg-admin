class Room < ApplicationRecord
  belongs_to :workspace

  validates :name, :category, :capacity, :whiteboard, :projector, :is_available, presence: true

  def is_occupied?
    Booking.where(room_id: id, status: 'confirmed')
           .where('start_time <= ? AND end_time >= ?', Time.current, Time.current)
           .exists?
  end
end
