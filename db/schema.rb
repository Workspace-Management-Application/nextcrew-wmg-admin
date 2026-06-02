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

ActiveRecord::Schema[8.0].define(version: 2026_06_02_000000) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

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
    t.string "service_name", null: false
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.datetime "created_at", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "amenities", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "bookings", force: :cascade do |t|
    t.string "booker_name"
    t.string "phone_number"
    t.integer "room_id"
    t.datetime "start_time"
    t.datetime "end_time"
    t.string "status"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "company_id"
    t.index ["company_id"], name: "index_bookings_on_company_id"
  end

  create_table "companies", force: :cascade do |t|
    t.string "name"
    t.string "email"
    t.string "phone_number"
    t.string "address"
    t.string "status"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "cabin_number"
    t.integer "no_of_employee"
    t.integer "meeting_time_limit_per_month"
    t.integer "no_of_meeting_per_day"
    t.integer "minimum_minutes_meeting_limit"
    t.integer "max_minutes_meeting_limit"
    t.integer "meeting_time_limit_per_day", null: false
    t.boolean "parallel_booking", default: false, null: false
    t.string "centre_address"
    t.date "commencement_date"
    t.integer "lock_in_period"
    t.integer "no_of_seats"
    t.string "floor_no"
    t.string "shift_type"
    t.date "agreement_date"
    t.string "company_poc_contact"
    t.string "company_email_address"
    t.boolean "name_board_charges"
    t.date "lease_expiry_date"
    t.integer "cost_per_seat"
  end

  create_table "company_rooms", force: :cascade do |t|
    t.bigint "company_id", null: false
    t.bigint "room_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["company_id"], name: "index_company_rooms_on_company_id"
    t.index ["room_id"], name: "index_company_rooms_on_room_id"
  end

  create_table "company_users", force: :cascade do |t|
    t.integer "company_id"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "company_workspaces", force: :cascade do |t|
    t.integer "company_id"
    t.integer "workspace_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "day_passes", force: :cascade do |t|
    t.integer "workspace_id"
    t.string "name"
    t.string "phone_number"
    t.string "email"
    t.date "pass_date"
    t.string "photo"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "company_name"
  end

  create_table "jwt_denylists", force: :cascade do |t|
    t.string "jti"
    t.datetime "exp"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["jti"], name: "index_jwt_denylists_on_jti"
  end

  create_table "office_enquiries", force: :cascade do |t|
    t.integer "workspace_id"
    t.string "enquirer_name"
    t.string "visitor_name"
    t.string "phone_number"
    t.string "email"
    t.string "company_name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "no_of_seats"
  end

  create_table "office_enquiry_workspace_types", force: :cascade do |t|
    t.bigint "office_enquiry_id", null: false
    t.bigint "workspace_type_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["office_enquiry_id"], name: "index_office_enquiry_workspace_types_on_office_enquiry_id"
    t.index ["workspace_type_id"], name: "index_office_enquiry_workspace_types_on_workspace_type_id"
  end

  create_table "room_amenities", force: :cascade do |t|
    t.bigint "room_id", null: false
    t.bigint "amenity_id", null: false
    t.boolean "has_amenity"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["amenity_id"], name: "index_room_amenities_on_amenity_id"
    t.index ["room_id"], name: "index_room_amenities_on_room_id"
  end

  create_table "rooms", force: :cascade do |t|
    t.string "name"
    t.string "category"
    t.bigint "workspace_id", null: false
    t.integer "capacity"
    t.boolean "is_available", default: true
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["workspace_id"], name: "index_rooms_on_workspace_id"
  end

  create_table "user_workspaces", force: :cascade do |t|
    t.integer "user_id"
    t.integer "workspace_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.string "confirmation_token"
    t.datetime "confirmed_at"
    t.datetime "confirmation_sent_at"
    t.string "unconfirmed_email"
    t.integer "failed_attempts", default: 0, null: false
    t.string "unlock_token"
    t.datetime "locked_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "role"
    t.string "refresh_token"
    t.string "name"
    t.string "phone_number"
    t.jsonb "sidebar_items"
    t.index ["confirmation_token"], name: "index_users_on_confirmation_token", unique: true
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.index ["unlock_token"], name: "index_users_on_unlock_token", unique: true
  end

  create_table "visitor_entries", force: :cascade do |t|
    t.string "name"
    t.integer "workspace_id"
    t.string "person_to_visit_name"
    t.string "phone_number"
    t.string "email"
    t.string "purpose"
    t.string "image"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "workspace_types", force: :cascade do |t|
    t.string "name", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_workspace_types_on_name", unique: true
  end

  create_table "workspace_workspace_types", force: :cascade do |t|
    t.bigint "workspace_id", null: false
    t.bigint "workspace_type_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["workspace_id"], name: "index_workspace_workspace_types_on_workspace_id"
    t.index ["workspace_type_id"], name: "index_workspace_workspace_types_on_workspace_type_id"
  end

  create_table "workspaces", force: :cascade do |t|
    t.string "name"
    t.string "building_name"
    t.text "address"
    t.string "city"
    t.string "pincode"
    t.string "photo"
    t.boolean "is_active"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "status", default: "pending", null: false
    t.integer "wizard_step", default: 1, null: false
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "bookings", "companies"
  add_foreign_key "company_rooms", "companies"
  add_foreign_key "company_rooms", "rooms"
  add_foreign_key "office_enquiry_workspace_types", "office_enquiries"
  add_foreign_key "office_enquiry_workspace_types", "workspace_types"
  add_foreign_key "room_amenities", "amenities"
  add_foreign_key "room_amenities", "rooms"
  add_foreign_key "rooms", "workspaces"
  add_foreign_key "workspace_workspace_types", "workspace_types"
  add_foreign_key "workspace_workspace_types", "workspaces"
end
