class RemoveCheckTermsFromStepProcesses < ActiveRecord::Migration[6.0]
  def change
    remove_column :step_processes, :check_terms, :boolean
  end
end
