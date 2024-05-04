class AddUniqueConstraintToStepIdx < ActiveRecord::Migration[6.0]
  def change
    remove_index :step_archives, :batch_id
    add_index :step_archives, :batch_id, unique: true, name: "index_step_archives_on_batch_id"

    remove_index :step_preprocesses, :batch_id
    add_index :step_preprocesses, :batch_id, unique: true, name: "index_step_preprocesses_on_batch_id"

    remove_index :step_processes, :batch_id
    add_index :step_processes, :batch_id, unique: true, name: "index_step_processes_on_batch_id"

    remove_index :step_transfers, :batch_id
    add_index :step_transfers, :batch_id, unique: true, name: "index_step_transfers_on_batch_id"
  end
end
