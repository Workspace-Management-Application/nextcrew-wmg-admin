class WorkspaceWorkspaceType < ApplicationRecord
  belongs_to :workspace
  belongs_to :workspace_type
 
  validates :workspace_id, uniqueness: { scope: :workspace_type_id }
end 