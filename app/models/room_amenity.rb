class RoomAmenity < ApplicationRecord
  belongs_to :room
  belongs_to :amenity

  validates :room_id, uniqueness: { scope: :amenity_id }
  validates :has_amenity, inclusion: { in: [true, false] }

  attribute :has_amenity, :boolean, default: false
end
