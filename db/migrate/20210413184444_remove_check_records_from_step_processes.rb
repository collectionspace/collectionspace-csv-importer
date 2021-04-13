class RemoveCheckRecordsFromStepProcesses < ActiveRecord::Migration[6.0]
  def change
    remove_column :step_processes, :check_records, :boolean
  end
end
