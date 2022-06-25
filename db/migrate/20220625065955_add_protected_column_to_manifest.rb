class AddProtectedColumnToManifest < ActiveRecord::Migration[6.0]
  def change
    add_column :manifests, :enabled, :boolean, default: true
  end
end
