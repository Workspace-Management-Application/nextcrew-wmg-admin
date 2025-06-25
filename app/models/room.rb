class Room < ApplicationRecord
  belongs_to :workspace

  validates :name, :category, :capacity, presence: true
  validates :whiteboard, :projector, :is_available, inclusion: { in: [true, false] }

  def is_occupied?
    Booking.where(room_id: id, status: 'confirmed')
           .where('start_time <= ? AND end_time >= ?', Time.current, Time.current)
           .exists?
  end
end
