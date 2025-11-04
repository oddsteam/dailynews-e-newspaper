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

ActiveRecord::Schema[8.1].define(version: 2025_11_03_023514) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "action_text_rich_texts", force: :cascade do |t|
    t.text "body"
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.bigint "record_id", null: false
    t.string "record_type", null: false
    t.datetime "updated_at", null: false
    t.index ["record_type", "record_id", "name"], name: "index_action_text_rich_texts_uniqueness", unique: true
  end

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

  create_table "admin_invitations", force: :cascade do |t|
    t.datetime "accepted_at"
    t.integer "admin_user_id"
    t.datetime "created_at", null: false
    t.string "email", null: false
    t.datetime "expires_at", null: false
    t.integer "invited_by_id", null: false
    t.integer "status", default: 0, null: false
    t.string "token", null: false
    t.datetime "updated_at", null: false
    t.index ["admin_user_id"], name: "index_admin_invitations_on_admin_user_id"
    t.index ["email"], name: "index_admin_invitations_on_email"
    t.index ["expires_at"], name: "index_admin_invitations_on_expires_at"
    t.index ["status"], name: "index_admin_invitations_on_status"
    t.index ["token"], name: "index_admin_invitations_on_token", unique: true
  end

  create_table "admin_users", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.datetime "remember_created_at"
    t.datetime "reset_password_sent_at"
    t.string "reset_password_token"
    t.integer "status", default: 1, null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_admin_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_admin_users_on_reset_password_token", unique: true
    t.index ["status"], name: "index_admin_users_on_status"
  end

  create_table "cart_items", force: :cascade do |t|
    t.bigint "cart_id"
    t.datetime "created_at", null: false
    t.bigint "product_id", null: false
    t.datetime "updated_at", null: false
    t.index ["cart_id"], name: "index_cart_items_on_cart_id"
    t.index ["product_id"], name: "index_cart_items_on_product_id"
  end

  create_table "carts", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["user_id"], name: "index_carts_on_user_id"
  end

  create_table "companies", force: :cascade do |t|
    t.string "address_1", null: false
    t.string "address_2"
    t.string "country", null: false
    t.datetime "created_at", null: false
    t.string "district", null: false
    t.string "email", null: false
    t.string "name", null: false
    t.string "phone_number", null: false
    t.string "postal_code", null: false
    t.string "province", null: false
    t.string "sub_district", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_companies_on_name", unique: true
  end

  create_table "newspapers", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "description"
    t.string "original_filename"
    t.datetime "published_at"
    t.string "title"
    t.datetime "updated_at", null: false
    t.index ["original_filename"], name: "index_newspapers_on_original_filename"
  end

  create_table "order_items", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "order_id", null: false
    t.bigint "product_id", null: false
    t.datetime "updated_at", null: false
    t.index ["order_id"], name: "index_order_items_on_order_id"
    t.index ["product_id"], name: "index_order_items_on_product_id"
  end

  create_table "orders", force: :cascade do |t|
    t.string "charge_id"
    t.datetime "created_at", null: false
    t.integer "state", default: 0, null: false
    t.integer "sub_total_cents", default: 0, null: false
    t.string "sub_total_currency", default: "THB", null: false
    t.integer "total_cents", default: 0, null: false
    t.string "total_currency", default: "THB", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["state"], name: "index_orders_on_state"
    t.index ["user_id"], name: "index_orders_on_user_id"
  end

  create_table "pdf_import_operations", force: :cascade do |t|
    t.datetime "completed_at"
    t.datetime "created_at", null: false
    t.text "error_message"
    t.integer "failed_count", default: 0
    t.integer "imported_count", default: 0
    t.jsonb "log", default: {}
    t.bigint "pdf_source_id", null: false
    t.integer "skipped_count", default: 0
    t.datetime "started_at", null: false
    t.string "status", default: "running", null: false
    t.datetime "updated_at", null: false
    t.index ["pdf_source_id"], name: "index_pdf_import_operations_on_pdf_source_id"
    t.index ["started_at"], name: "index_pdf_import_operations_on_started_at"
    t.index ["status"], name: "index_pdf_import_operations_on_status"
  end

  create_table "pdf_sources", force: :cascade do |t|
    t.string "bucket_name", null: false
    t.string "bucket_path", default: "/"
    t.datetime "created_at", null: false
    t.boolean "enabled", default: false, null: false
    t.text "last_import_log"
    t.string "last_import_status", default: "idle"
    t.datetime "last_imported_at"
    t.datetime "updated_at", null: false
  end

  create_table "products", force: :cascade do |t|
    t.integer "amount_cents", default: 0, null: false
    t.string "amount_currency", default: "THB", null: false
    t.datetime "created_at", null: false
    t.string "sku"
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.index ["sku"], name: "index_products_on_sku", unique: true
    t.index ["title"], name: "index_products_on_title", unique: true
  end

  create_table "subscriptions", force: :cascade do |t|
    t.boolean "auto_renew", default: true
    t.datetime "created_at", null: false
    t.date "end_date", null: false
    t.datetime "last_renewal_attempt_at"
    t.bigint "order_id"
    t.integer "renewal_attempts", default: 0, null: false
    t.datetime "renewal_failed_at"
    t.integer "renewal_status", default: 0, null: false
    t.datetime "renewal_succeeded_at"
    t.date "start_date", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["auto_renew", "end_date", "renewal_status"], name: "index_subscriptions_on_renewal_query"
    t.index ["order_id"], name: "index_subscriptions_on_order_id"
    t.index ["user_id"], name: "index_subscriptions_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email"
    t.string "encrypted_password"
    t.string "first_name"
    t.string "last_name"
    t.string "omise_customer_id"
    t.datetime "remember_created_at"
    t.datetime "reset_password_sent_at"
    t.string "reset_password_token"
    t.string "type"
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.index ["type"], name: "index_users_on_type"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "admin_invitations", "admin_users"
  add_foreign_key "admin_invitations", "admin_users", column: "invited_by_id"
  add_foreign_key "cart_items", "carts"
  add_foreign_key "cart_items", "products"
  add_foreign_key "carts", "users"
  add_foreign_key "order_items", "orders"
  add_foreign_key "order_items", "products"
  add_foreign_key "orders", "users"
  add_foreign_key "pdf_import_operations", "pdf_sources"
  add_foreign_key "subscriptions", "orders"
  add_foreign_key "subscriptions", "users"
end
