# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 2019_05_31_101710) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "pgcrypto"
  enable_extension "plpgsql"

  create_table "local_authorities", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.integer "code"
    t.string "name"
    t.index ["code"], name: "index_local_authorities_on_code", unique: true
  end

  create_table "local_authority_districts", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "name"
    t.string "code"
    t.index ["code"], name: "index_local_authority_districts_on_code", unique: true
  end

  create_table "schools", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.integer "urn", null: false
    t.string "name", null: false
    t.string "street"
    t.string "locality"
    t.string "town"
    t.string "county"
    t.string "postcode"
    t.integer "phase", null: false
    t.integer "school_type_group", null: false
    t.integer "school_type", null: false
    t.uuid "local_authority_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.uuid "local_authority_district_id"
    t.index ["local_authority_district_id"], name: "index_schools_on_local_authority_district_id"
    t.index ["local_authority_id"], name: "index_schools_on_local_authority_id"
    t.index ["urn"], name: "index_schools_on_urn", unique: true
  end

  create_table "tslr_claims", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "qts_award_year"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.uuid "claim_school_id"
    t.integer "employment_status"
    t.uuid "current_school_id"
    t.string "full_name", limit: 200
    t.string "address_line_1", limit: 100
    t.string "address_line_2", limit: 100
    t.string "address_line_3", limit: 100
    t.string "address_line_4", limit: 100
    t.string "postcode", limit: 11
    t.date "date_of_birth"
    t.string "teacher_reference_number", limit: 11
    t.string "national_insurance_number", limit: 9
    t.string "email_address", limit: 256
    t.boolean "mostly_teaching_eligible_subjects"
    t.string "bank_sort_code", limit: 6
    t.string "bank_account_number", limit: 8
    t.datetime "submitted_at"
    t.decimal "student_loan_repayment_amount", precision: 7, scale: 2
    t.index ["claim_school_id"], name: "index_tslr_claims_on_claim_school_id"
    t.index ["current_school_id"], name: "index_tslr_claims_on_current_school_id"
    t.index ["employment_status"], name: "index_tslr_claims_on_employment_status"
    t.index ["submitted_at"], name: "index_tslr_claims_on_submitted_at"
  end

  add_foreign_key "schools", "local_authority_districts"
  add_foreign_key "tslr_claims", "schools", column: "claim_school_id"
  add_foreign_key "tslr_claims", "schools", column: "current_school_id"
end
