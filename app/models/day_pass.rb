class DayPass < ApplicationRecord
  belongs_to :workspace

  validates :name, :email, :phone_number, :pass_date, :purpose, presence: true
end
