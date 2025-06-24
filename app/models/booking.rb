class Booking < ApplicationRecord
  belongs_to :user
  belongs_to :room

  enum status: { confirmed: 'confirmed', completed: 'completed', cancelled: 'cancelled' }
end
