# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_05_22_083515) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "active_storage_attachments", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.bigint "record_id", null: false
    t.string "record_type", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.string "content_type"
    t.datetime "created_at", null: false
    t.string "filename", null: false
    t.string "key", null: false
    t.text "metadata"
    t.string "service_name", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "app_settings", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "key", null: false
    t.datetime "updated_at", null: false
    t.string "value"
    t.index ["key"], name: "index_app_settings_on_key", unique: true
  end

  create_table "bulk_assessment_items", force: :cascade do |t|
    t.text "ai_result"
    t.bigint "bulk_assessment_id", null: false
    t.datetime "created_at", null: false
    t.text "error_message"
    t.integer "estimated_price"
    t.string "name"
    t.integer "position", default: 1, null: false
    t.integer "status", default: 0, null: false
    t.string "suggested_action"
    t.datetime "updated_at", null: false
    t.index ["bulk_assessment_id", "position"], name: "index_bulk_assessment_items_on_bulk_assessment_id_and_position"
    t.index ["bulk_assessment_id"], name: "index_bulk_assessment_items_on_bulk_assessment_id"
  end

  create_table "bulk_assessments", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "session_token"
    t.integer "status", default: 0, null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id"
    t.index ["session_token"], name: "index_bulk_assessments_on_session_token"
    t.index ["user_id"], name: "index_bulk_assessments_on_user_id"
  end

  create_table "businesses", force: :cascade do |t|
    t.boolean "active", default: false, null: false
    t.string "area"
    t.integer "category", default: 0
    t.datetime "created_at", null: false
    t.text "description"
    t.string "name", null: false
    t.string "phone"
    t.integer "plan", default: 0
    t.string "stripe_customer_id"
    t.string "stripe_subscription_id"
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.string "website"
    t.index ["user_id"], name: "index_businesses_on_user_id"
  end

  create_table "consultations", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "message"
    t.text "response"
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["user_id"], name: "index_consultations_on_user_id"
  end

  create_table "guest_assessment_sessions", force: :cascade do |t|
    t.integer "assessed_count", default: 0, null: false
    t.datetime "created_at", null: false
    t.string "token", null: false
    t.datetime "updated_at", null: false
    t.index ["token"], name: "index_guest_assessment_sessions_on_token", unique: true
  end

  create_table "inquiries", force: :cascade do |t|
    t.bigint "business_id", null: false
    t.datetime "created_at", null: false
    t.bigint "item_id"
    t.text "message", null: false
    t.integer "status", default: 0
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["business_id"], name: "index_inquiries_on_business_id"
    t.index ["item_id"], name: "index_inquiries_on_item_id"
    t.index ["user_id"], name: "index_inquiries_on_user_id"
  end

  create_table "items", force: :cascade do |t|
    t.integer "action", default: 0
    t.text "ai_result"
    t.datetime "created_at", null: false
    t.decimal "estimated_price", precision: 10
    t.text "memo"
    t.string "name"
    t.string "status", default: "pending"
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["user_id"], name: "index_items_on_user_id"
  end

  create_table "memories", force: :cascade do |t|
    t.text "comment"
    t.datetime "created_at", null: false
    t.bigint "item_id"
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["item_id"], name: "index_memories_on_item_id"
    t.index ["user_id"], name: "index_memories_on_user_id"
  end

  create_table "todo_items", force: :cascade do |t|
    t.integer "category", default: 0
    t.boolean "completed", default: false, null: false
    t.datetime "created_at", null: false
    t.integer "priority", default: 1
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["user_id"], name: "index_todo_items_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "city"
    t.datetime "created_at", null: false
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "name", default: "", null: false
    t.string "prefecture"
    t.datetime "remember_created_at"
    t.datetime "reset_password_sent_at"
    t.string "reset_password_token"
    t.integer "role", default: 0, null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "bulk_assessment_items", "bulk_assessments"
  add_foreign_key "bulk_assessments", "users"
  add_foreign_key "businesses", "users"
  add_foreign_key "consultations", "users"
  add_foreign_key "inquiries", "businesses"
  add_foreign_key "inquiries", "items"
  add_foreign_key "inquiries", "users"
  add_foreign_key "items", "users"
  add_foreign_key "memories", "items"
  add_foreign_key "memories", "users"
  add_foreign_key "todo_items", "users"
end
