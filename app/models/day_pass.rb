class DayPass < ApplicationRecord
  belongs_to :workspace

  validates :name, :email, :phone_number, :pass_date, :photo, :purpose, presence: true
end
