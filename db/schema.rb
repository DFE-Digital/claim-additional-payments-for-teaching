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

ActiveRecord::Schema.define(version: 2019_11_20_120237) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "pgcrypto"
  enable_extension "plpgsql"

  create_table "checks", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.integer "result"
    t.string "checked_by"
    t.uuid "claim_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "notes"
    t.index ["claim_id"], name: "index_checks_on_claim_id"
  end

  create_table "claims", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "address_line_1", limit: 100
    t.string "address_line_2", limit: 100
    t.string "address_line_3", limit: 100
    t.string "address_line_4", limit: 100
    t.string "postcode", limit: 11
    t.date "date_of_birth"
    t.string "teacher_reference_number", limit: 11
    t.string "national_insurance_number", limit: 9
    t.string "email_address", limit: 256
    t.string "bank_sort_code", limit: 6
    t.string "bank_account_number", limit: 8
    t.datetime "submitted_at"
    t.string "reference", limit: 8
    t.boolean "has_student_loan"
    t.integer "student_loan_country"
    t.integer "student_loan_courses"
    t.integer "student_loan_start_date"
    t.integer "student_loan_plan"
    t.integer "payroll_gender"
    t.text "verified_fields", default: [], array: true
    t.string "eligibility_type"
    t.uuid "eligibility_id"
    t.json "verify_response"
    t.string "first_name", limit: 100
    t.string "middle_name", limit: 100
    t.string "surname", limit: 100
    t.string "banking_name"
    t.string "building_society_roll_number"
    t.index ["eligibility_type", "eligibility_id"], name: "index_claims_on_eligibility_type_and_eligibility_id"
    t.index ["reference"], name: "index_claims_on_reference", unique: true
    t.index ["submitted_at"], name: "index_claims_on_submitted_at"
  end

  create_table "data_migrations", primary_key: "version", id: :string, force: :cascade do |t|
  end

  create_table "delayed_jobs", force: :cascade do |t|
    t.integer "priority", default: 0, null: false
    t.integer "attempts", default: 0, null: false
    t.text "handler", null: false
    t.text "last_error"
    t.datetime "run_at"
    t.datetime "locked_at"
    t.datetime "failed_at"
    t.string "locked_by"
    t.string "queue"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "cron"
    t.index ["priority", "run_at"], name: "delayed_jobs_priority"
  end

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

  create_table "maths_and_physics_eligibilities", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.boolean "teaching_maths_or_physics"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.uuid "current_school_id"
    t.boolean "initial_teacher_training_specialised_in_maths_or_physics"
    t.integer "has_uk_maths_or_physics_degree"
    t.integer "qts_award_year"
    t.index ["current_school_id"], name: "index_maths_and_physics_eligibilities_on_current_school_id"
  end

  create_table "payments", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "claim_id"
    t.uuid "payroll_run_id"
    t.decimal "award_amount", precision: 7, scale: 2
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "payroll_reference"
    t.decimal "gross_value", precision: 7, scale: 2
    t.decimal "national_insurance", precision: 7, scale: 2
    t.decimal "employers_national_insurance", precision: 7, scale: 2
    t.decimal "student_loan_repayment", precision: 7, scale: 2
    t.decimal "tax", precision: 7, scale: 2
    t.decimal "net_pay", precision: 7, scale: 2
    t.index ["claim_id"], name: "index_payments_on_claim_id", unique: true
    t.index ["payroll_run_id"], name: "index_payments_on_payroll_run_id"
  end

  create_table "payroll_runs", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "created_by"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "confirmation_report_uploaded_by"
  end

  create_table "policy_configurations", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "policy_type", null: false
    t.boolean "open_for_submissions", default: true, null: false
    t.string "availability_message"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["policy_type"], name: "index_policy_configurations_on_policy_type", unique: true
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
    t.date "close_date"
    t.integer "establishment_number"
    t.index ["local_authority_district_id"], name: "index_schools_on_local_authority_district_id"
    t.index ["local_authority_id"], name: "index_schools_on_local_authority_id"
    t.index ["urn"], name: "index_schools_on_urn", unique: true
  end

  create_table "student_loans_eligibilities", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "qts_award_year"
    t.uuid "claim_school_id"
    t.uuid "current_school_id"
    t.integer "employment_status"
    t.boolean "biology_taught"
    t.boolean "chemistry_taught"
    t.boolean "computing_taught"
    t.boolean "languages_taught"
    t.boolean "physics_taught"
    t.boolean "taught_eligible_subjects"
    t.decimal "student_loan_repayment_amount", precision: 7, scale: 2
    t.boolean "had_leadership_position"
    t.boolean "mostly_performed_leadership_duties"
    t.index ["claim_school_id"], name: "index_student_loans_eligibilities_on_claim_school_id"
    t.index ["current_school_id"], name: "index_student_loans_eligibilities_on_current_school_id"
  end

  add_foreign_key "maths_and_physics_eligibilities", "schools", column: "current_school_id"
  add_foreign_key "payments", "claims"
  add_foreign_key "payments", "payroll_runs"
  add_foreign_key "schools", "local_authority_districts"
  add_foreign_key "student_loans_eligibilities", "schools", column: "claim_school_id"
  add_foreign_key "student_loans_eligibilities", "schools", column: "current_school_id"
end
