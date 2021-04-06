# frozen_string_literal: true

class CreateMappers < ActiveRecord::Migration[6.0]
  def change
    create_table :mappers do |t|
      t.string :title, null: false, unique: true
      t.string :profile, null: false
      t.string :type, null: false
      t.string :version, null: false
      t.string :digest, null: false, unique: true
      t.string :url, null: false, unique: true
      t.boolean :enabled, null: false, default: true
      t.boolean :status, null: false
      t.integer :batches_count, default: 0

      t.timestamps
    end

    add_index :mappers, :title, unique: true
    add_index :mappers, %i[profile version type], unique: true
  end
end
