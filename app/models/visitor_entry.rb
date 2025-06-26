class VisitorEntry < ApplicationRecord
  belongs_to :workspace

  validates :name, :email, :phone_number, presence: true

end
