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
  has_many_attached :documents

  # Enum declaration with a default value
  enum :role, { super_admin: 'super_admin', admin: 'admin', floor_user: 'floor_user', user: 'user' }, default: :user
  enum :company_user_type, { booking_user: 'booking_user', employee: 'employee' }, default: :booking_user

  validates :company_user_type, inclusion: { in: company_user_types.keys }, if: :user?
  validate :documents_must_be_images_or_pdfs

  before_validation :normalize_company_user_type
  before_save :clear_password_for_employee
  before_create :generate_token

  SIDEBAR_ITEMS = {
    "dashboard" => "Dashboard",
    "workspaces" => "Workspaces",
    "rooms" => "Rooms",
    "bookings" => "Bookings",
    "users" => "Users",
    "companies" => "Companies",
    "office_enquiries" => "Office Enquiries",
    "visitor_entries" => "Visitor Entries",
    "day_passes" => "Day Passes",
    "workspace_types" => "Workspace Types",
    "amenities" => "Amenities",
    "exports" => "Export"
  }.freeze

  # Check if user can access web interface
  def can_access_web?
    admin? || super_admin?
  end

  # Check if user should use mobile app only
  def mobile_only?
    user? || floor_user?
  end

  def visible_sidebar_items
    return SIDEBAR_ITEMS.keys if super_admin? || sidebar_items.nil?

    sidebar_items & SIDEBAR_ITEMS.keys
  end

  def sidebar_item_visible?(key)
    visible_sidebar_items.include?(key.to_s)
  end

  def company_user?
    user? && companies.any?
  end

  def company_user_type_label
    company_user_type.to_s.humanize
  end

  def can_book_for_company?
    !user? || booking_user?
  end

  # Employees are record-keeping only: no login, so Devise should never
  # require a password for them.
  def password_required?
    return false if employee?

    super
  end

  def api_profile_data
    data = as_json(only: [:id, :email, :name, :role]).merge(workspace_id: workspaces.first&.id)
    data[:company_user_type] = company_user_type if user?
    data
  end

  private

  def normalize_company_user_type
    self.company_user_type = user? ? (company_user_type.presence || 'booking_user') : nil
  end

  # Employees are record-keeping only and can never log in, even if a
  # password was submitted (e.g. an existing Booking User converted to
  # Employee) or tampered into the request.
  def clear_password_for_employee
    self.encrypted_password = '' if employee?
  end

  def documents_must_be_images_or_pdfs
    documents.each do |document|
      next if document.blob&.content_type.in?(%w[application/pdf image/jpeg image/jpg image/png image/gif image/webp])

      errors.add(:documents, "must be images or PDFs")
    end
  end

  def generate_token
    self.refresh_token = SecureRandom.hex(32)
  end
end
