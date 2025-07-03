class WorkspaceType < ApplicationRecord
  has_many :workspace_workspace_types, dependent: :destroy
  has_many :workspaces, through: :workspace_workspace_types

  validates :name, presence: true, uniqueness: true

  # Default workspace types
  DEFAULT_TYPES = [
    'Private Cabin',
    'Private Office', 
    'Private Desk',
    'Shared Desk'
  ].freeze

  def self.create_default_types
    DEFAULT_TYPES.each do |type_name|
      find_or_create_by(name: type_name)
    end
  end
end 