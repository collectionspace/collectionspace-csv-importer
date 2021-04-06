class CreateConnections < ActiveRecord::Migration[6.0]
  def change
    create_table :connections do |t|
      t.string :name, null: false
      t.string :url, null: false
      t.string :username, null: false
      t.text :password_ciphertext, null: false
      t.boolean :enabled, null: false, default: true
      t.boolean :primary, null: false, default: false
      t.string :profile, null: false
      t.references :user, null: false, foreign_key: true
      t.references :group, null: false, foreign_key: true

      t.timestamps
    end
  end
end
