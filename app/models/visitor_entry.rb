class VisitorEntry < ApplicationRecord
  belongs_to :workspace

  validates :name, :email, :phone_number, :person_to_visit_name, :photo, presence: true

end
