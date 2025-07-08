class Amenity < ApplicationRecord
  has_many :room_amenities, dependent: :destroy
  has_many :rooms, through: :room_amenities

  validates :name, presence: true, uniqueness: true

  DEFAULT_TYPES = [
    'Whiteboard',
    'Projector', 
    'TV'
  ].freeze

  def self.create_default_types
    DEFAULT_TYPES.each do |type_name|
      find_or_create_by(name: type_name)
    end
  end

  scope :default_amenities, -> { where(name: DEFAULT_TYPES) }
end
