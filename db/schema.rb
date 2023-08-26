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

ActiveRecord::Schema[7.0].define(version: 2023_08_26_000101) do
  create_table "bluesky_user_editors", force: :cascade do |t|
    t.integer "user_id", null: false
    t.integer "bluesky_user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["bluesky_user_id"], name: "index_bluesky_user_editors_on_bluesky_user_id"
    t.index ["user_id", "bluesky_user_id"], name: "index_bluesky_user_editors_on_user_id_and_bluesky_user_id", unique: true
    t.index ["user_id"], name: "index_bluesky_user_editors_on_user_id"
  end

  create_table "bluesky_users", force: :cascade do |t|
    t.integer "user_id", null: false
    t.string "token", null: false
    t.string "did", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "bluesky_client_marshalled"
    t.index ["did"], name: "index_bluesky_users_on_did", unique: true
    t.index ["token"], name: "index_bluesky_users_on_token", unique: true
    t.index ["user_id"], name: "index_bluesky_users_on_user_id"
  end

  create_table "half_tokens", force: :cascade do |t|
    t.string "token", null: false
    t.integer "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["token"], name: "index_half_tokens_on_token", unique: true
    t.index ["user_id"], name: "index_half_tokens_on_user_id"
  end

  create_table "new_user_email_confirmations", force: :cascade do |t|
    t.string "email", null: false
    t.string "token", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_new_user_email_confirmations_on_email"
    t.index ["token"], name: "index_new_user_email_confirmations_on_token", unique: true
  end

  create_table "totp_recovery_codes", force: :cascade do |t|
    t.integer "user_id", null: false
    t.string "code"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_totp_recovery_codes_on_user_id"
  end

  create_table "user_email_update_requests", force: :cascade do |t|
    t.integer "user_id", null: false
    t.string "email", null: false
    t.string "token", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["token"], name: "index_user_email_update_requests_on_token", unique: true
    t.index ["user_id"], name: "index_user_email_update_requests_on_user_id"
  end

  create_table "user_password_change_requests", force: :cascade do |t|
    t.integer "user_id", null: false
    t.string "token", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["token"], name: "index_user_password_change_requests_on_token", unique: true
    t.index ["user_id"], name: "index_user_password_change_requests_on_user_id"
  end

  create_table "user_tokens", force: :cascade do |t|
    t.string "token", null: false
    t.integer "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["token"], name: "index_user_tokens_on_token", unique: true
    t.index ["user_id"], name: "index_user_tokens_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", null: false
    t.string "password_digest"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "totp_secret"
    t.boolean "opendyslexic"
    t.index "\"half_token\"", name: "index_users_on_half_token"
    t.index "\"user_token\"", name: "index_users_on_user_token"
    t.index ["email"], name: "index_users_on_email", unique: true
  end

  add_foreign_key "bluesky_user_editors", "bluesky_users"
  add_foreign_key "bluesky_user_editors", "users"
  add_foreign_key "bluesky_users", "users"
  add_foreign_key "half_tokens", "users"
  add_foreign_key "totp_recovery_codes", "users"
  add_foreign_key "user_email_update_requests", "users"
  add_foreign_key "user_password_change_requests", "users"
  add_foreign_key "user_tokens", "users"
end
