class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable,
         :jwt_authenticatable,
         jwt_revocation_strategy: JwtDenylist

  has_many :company_users
  has_many :companies, through: :company_users
  has_one :user_workspace
  has_one :workspace, through: :user_workspace
  has_many :bookings

  # Enum declaration with a default value
  enum :role, { super_admin: 'super_admin', admin: 'admin', user: 'user' }, default: :user
  before_create :generate_token

  private

  def generate_token
    self.refresh_token = SecureRandom.hex(32)
  end
end
