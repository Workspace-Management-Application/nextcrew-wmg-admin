class Room < ApplicationRecord
  has_many :bookings, dependent: :destroy
  belongs_to :workspace
  has_many :company_rooms, dependent: :destroy
  has_many :companies, through: :company_rooms
  has_many :room_amenities, dependent: :destroy
  has_many :amenities, through: :room_amenities

  # Active Storage attachment for room photos
  has_one_attached :photo

  validates :name, :category, presence: true
  validates :capacity, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :price_per_hour, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :is_available, inclusion: { in: [true, false] }

  accepts_nested_attributes_for :room_amenities, allow_destroy: true

  def is_occupied?
    Booking.where(room_id: id, status: 'confirmed')
           .where('start_time <= ? AND end_time >= ?', Time.current, Time.current)
           .exists?
  end

  def has_amenity?(amenity_name)
    room_amenities.joins(:amenity).where(amenities: { name: amenity_name }, has_amenity: true).exists?
  end

  def whiteboard?
    has_amenity?('Whiteboard')
  end

  def projector?
    has_amenity?('Projector')
  end

  def tv?
    has_amenity?('TV')
  end
end
