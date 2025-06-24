class UserWorkspace < ApplicationRecord
  belongs_to :user
  belongs_to :workspace

  validates_uniqueness_of :workspace_id, scope: :user_id, message: 'User is already assigned to this workspace'
end
