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

ActiveRecord::Schema[8.1].define(version: 2026_01_27_163149) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "flashcards", force: :cascade do |t|
    t.text "back", null: false
    t.datetime "created_at", null: false
    t.text "front", null: false
    t.bigint "generation_id"
    t.string "source", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["generation_id"], name: "index_flashcards_on_generation_id"
    t.index ["user_id"], name: "index_flashcards_on_user_id"
  end

  create_table "generations", force: :cascade do |t|
    t.integer "accepted_edited_count"
    t.integer "accepted_unedited_count"
    t.datetime "created_at", null: false
    t.integer "generated_count", default: 0, null: false
    t.jsonb "generated_flashcards"
    t.integer "generation_duration"
    t.string "model"
    t.boolean "reviewed", default: false, null: false
    t.text "source_text", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["user_id"], name: "index_generations_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.datetime "remember_created_at"
    t.datetime "reset_password_sent_at"
    t.string "reset_password_token"
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  add_foreign_key "flashcards", "generations", on_delete: :cascade
  add_foreign_key "flashcards", "users", on_delete: :cascade
  add_foreign_key "generations", "users", on_delete: :cascade
end
