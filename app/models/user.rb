class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable,
         :jwt_authenticatable,
         jwt_revocation_strategy: JwtDenylist

  has_many :company_users
  has_many :companies, through: :company_users
  has_many :user_workspaces
  has_many :workspaces, through: :user_workspaces

  # Enum declaration with a default value
  enum :role, { super_admin: 'super_admin', admin: 'admin', floor_user: 'floor_user', user: 'user' }, default: :user
  before_create :generate_token

  # Check if user can access web interface
  def can_access_web?
    admin? || super_admin?
  end

  # Check if user should use mobile app only
  def mobile_only?
    user? || floor_user?
  end

  private

  def generate_token
    self.refresh_token = SecureRandom.hex(32)
  end
end
