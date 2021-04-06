# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `rails
# db:schema:load`. When creating a new database, `rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 2020_12_03_172131) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "active_storage_attachments", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.bigint "byte_size", null: false
    t.string "checksum", null: false
    t.datetime "created_at", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "affiliations", force: :cascade do |t|
    t.bigint "group_id"
    t.bigint "user_id"
    t.index ["group_id", "user_id"], name: "index_affiliations_on_group_id_and_user_id", unique: true
    t.index ["group_id"], name: "index_affiliations_on_group_id"
    t.index ["user_id"], name: "index_affiliations_on_user_id"
  end

  create_table "batches", force: :cascade do |t|
    t.string "name"
    t.string "job_id"
    t.integer "num_rows"
    t.string "step_state"
    t.string "status_state"
    t.bigint "user_id", null: false
    t.bigint "group_id", null: false
    t.bigint "connection_id"
    t.bigint "mapper_id"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.text "batch_config", default: "{}"
    t.index ["connection_id"], name: "index_batches_on_connection_id"
    t.index ["group_id"], name: "index_batches_on_group_id"
    t.index ["mapper_id"], name: "index_batches_on_mapper_id"
    t.index ["user_id"], name: "index_batches_on_user_id"
  end

  create_table "connections", force: :cascade do |t|
    t.string "name", null: false
    t.string "url", null: false
    t.string "username", null: false
    t.text "password_ciphertext", null: false
    t.boolean "enabled", default: true, null: false
    t.boolean "primary", default: false, null: false
    t.string "domain"
    t.string "profile", null: false
    t.bigint "user_id", null: false
    t.bigint "group_id", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["group_id"], name: "index_connections_on_group_id"
    t.index ["user_id"], name: "index_connections_on_user_id"
  end

  create_table "groups", force: :cascade do |t|
    t.string "name", null: false
    t.string "description"
    t.string "domain"
    t.string "email"
    t.boolean "enabled", default: true, null: false
    t.string "profile"
    t.boolean "supergroup", default: false, null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["name"], name: "index_groups_on_name", unique: true
    t.index ["supergroup"], name: "index_groups_on_supergroup", unique: true, where: "(supergroup IS TRUE)"
  end

  create_table "mappers", force: :cascade do |t|
    t.string "title", null: false
    t.string "profile", null: false
    t.string "type", null: false
    t.string "version", null: false
    t.string "digest", null: false
    t.string "url", null: false
    t.boolean "enabled", default: true, null: false
    t.boolean "status", null: false
    t.integer "batches_count", default: 0
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["profile", "version", "type"], name: "index_mappers_on_profile_and_version_and_type", unique: true
    t.index ["title"], name: "index_mappers_on_title", unique: true
  end

  create_table "roles", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["name"], name: "index_roles_on_name", unique: true
  end

  create_table "step_archives", force: :cascade do |t|
    t.boolean "done", default: false, null: false
    t.datetime "started_at"
    t.datetime "completed_at"
    t.integer "step_num_row", default: 0
    t.integer "step_errors", default: 0
    t.integer "step_warnings", default: 0
    t.json "messages", default: []
    t.bigint "batch_id", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["batch_id"], name: "index_step_archives_on_batch_id"
  end

  create_table "step_preprocesses", force: :cascade do |t|
    t.boolean "done", default: false, null: false
    t.datetime "started_at"
    t.datetime "completed_at"
    t.integer "step_num_row", default: 0
    t.integer "step_errors", default: 0
    t.integer "step_warnings", default: 0
    t.json "messages", default: []
    t.bigint "batch_id", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["batch_id"], name: "index_step_preprocesses_on_batch_id"
  end

  create_table "step_processes", force: :cascade do |t|
    t.boolean "done", default: false, null: false
    t.datetime "started_at"
    t.datetime "completed_at"
    t.integer "step_num_row", default: 0
    t.integer "step_errors", default: 0
    t.integer "step_warnings", default: 0
    t.json "messages", default: []
    t.bigint "batch_id", null: false
    t.boolean "check_records", default: true, null: false
    t.boolean "check_terms", default: true, null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.json "row_results", default: {}
    t.index ["batch_id"], name: "index_step_processes_on_batch_id"
  end

  create_table "step_transfers", force: :cascade do |t|
    t.boolean "done", default: false, null: false
    t.datetime "started_at"
    t.datetime "completed_at"
    t.integer "step_num_row", default: 0
    t.integer "step_errors", default: 0
    t.integer "step_warnings", default: 0
    t.json "messages", default: []
    t.bigint "batch_id", null: false
    t.boolean "action_create", default: false, null: false
    t.boolean "action_update", default: false, null: false
    t.boolean "action_delete", default: false, null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["batch_id"], name: "index_step_transfers_on_batch_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.boolean "active", default: true, null: false
    t.boolean "enabled", default: false, null: false
    t.boolean "superuser", default: false, null: false
    t.bigint "group_id", null: false
    t.bigint "role_id", null: false
    t.integer "connections_count", default: 0
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["group_id"], name: "index_users_on_group_id"
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.index ["role_id"], name: "index_users_on_role_id"
    t.index ["superuser"], name: "index_users_on_superuser", unique: true, where: "(superuser IS TRUE)"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "batches", "connections"
  add_foreign_key "batches", "groups"
  add_foreign_key "batches", "mappers"
  add_foreign_key "batches", "users"
  add_foreign_key "connections", "groups"
  add_foreign_key "connections", "users"
  add_foreign_key "step_archives", "batches"
  add_foreign_key "step_preprocesses", "batches"
  add_foreign_key "step_processes", "batches"
  add_foreign_key "step_transfers", "batches"
  add_foreign_key "users", "groups"
  add_foreign_key "users", "roles"
end
