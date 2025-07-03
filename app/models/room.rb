class Room < ApplicationRecord
  has_many :bookings, dependent: :destroy
  belongs_to :workspace
  has_many :company_rooms, dependent: :destroy
  has_many :companies, through: :company_rooms

  # Active Storage attachment for room photos
  has_one_attached :photo

  validates :name, :category, presence: true
  validates :capacity, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :whiteboard, :projector, :tv, :is_available, inclusion: { in: [true, false] }

  def is_occupied?
    Booking.where(room_id: id, status: 'confirmed')
           .where('start_time <= ? AND end_time >= ?', Time.current, Time.current)
           .exists?
  end
end
