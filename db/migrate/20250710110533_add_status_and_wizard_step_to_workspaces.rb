class AddStatusAndWizardStepToWorkspaces < ActiveRecord::Migration[8.0]
  def change
    add_column :workspaces, :status, :string, default: 'pending', null: false 
    add_column :workspaces, :wizard_step, :integer, default: 1, null: false 
  end
end
