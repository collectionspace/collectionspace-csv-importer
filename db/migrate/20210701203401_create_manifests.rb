class CreateManifests < ActiveRecord::Migration[6.0]
  def change
    create_table :manifests do |t|
      t.string :name, null: false, unique: true
      t.string :url, null: false, unique: true
      t.integer :mappers_count, default: 0
    end
    add_reference :mappers, :manifest, foreign_key: true, null: false
  end
end
