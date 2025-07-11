class Workspace < ApplicationRecord
  has_many :company_workspaces,  dependent: :destroy
  has_many :companies, through: :company_workspaces,  dependent: :destroy
  has_many :user_workspaces,  dependent: :destroy
  has_many :users, through: :user_workspaces,  dependent: :destroy
  has_many :rooms,  dependent: :destroy
  has_many :day_passes,  dependent: :destroy
  has_many :visitor_entries,  dependent: :destroy
  has_many :office_enquiries, dependent: :destroy
  has_many :workspace_workspace_types, dependent: :destroy
  has_many :workspace_types, through: :workspace_workspace_types

  # Active Storage attachment for workspace photos
  has_one_attached :photo

  validates :name, :building_name, :address, :city, :pincode, presence: true
  validates :is_active, inclusion: { in: [true, false] }
  validates :status, presence: true
  validates :wizard_step, presence: true, numericality: { only_integer: true, greater_than: 0, less_than_or_equal_to: 4 }

  # Set default value for is_active
  attribute :is_active, :boolean, default: true

  # Callbacks
  after_create :associate_super_admins

  enum :status, { pending: 'pending', confirmed: 'confirmed' }

  accepts_nested_attributes_for :rooms, allow_destroy: true, reject_if: proc { |attributes| attributes['name'].blank? && attributes['category'].blank? && attributes['capacity'].blank? }

  private

  # Automatically associate all super_admin users with newly created workspace
  def associate_super_admins
    User.where(role: 'super_admin').find_each do |super_admin|
      UserWorkspace.create!(
        user: super_admin,
        workspace: self
      )
    end
    
    Rails.logger.info "Associated #{User.where(role: 'super_admin').count} super_admin users with workspace '#{self.name}'"
  rescue => e
    Rails.logger.error "Failed to associate super_admins with workspace #{self.id}: #{e.message}"
  end
end
