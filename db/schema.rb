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

ActiveRecord::Schema.define(version: 2021_04_08_151248) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "pgcrypto"
  enable_extension "plpgsql"

  create_table "amendments", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "claim_id"
    t.text "notes"
    t.string "claim_changes"
    t.uuid "dfe_sign_in_users_id"
    t.uuid "created_by_id"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.datetime "personal_data_removed_at"
    t.index ["claim_id"], name: "index_amendments_on_claim_id"
    t.index ["created_by_id"], name: "index_amendments_on_created_by_id"
    t.index ["dfe_sign_in_users_id"], name: "index_amendments_on_dfe_sign_in_users_id"
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
    t.text "govuk_verify_fields", default: [], array: true
    t.string "eligibility_type"
    t.uuid "eligibility_id"
    t.string "first_name", limit: 100
    t.string "middle_name", limit: 100
    t.string "surname", limit: 100
    t.string "banking_name"
    t.string "building_society_roll_number"
    t.uuid "payment_id"
    t.datetime "personal_data_removed_at"
    t.string "academic_year", limit: 9
    t.index ["academic_year"], name: "index_claims_on_academic_year"
    t.index ["created_at"], name: "index_claims_on_created_at"
    t.index ["eligibility_type", "eligibility_id"], name: "index_claims_on_eligibility_type_and_eligibility_id"
    t.index ["payment_id"], name: "index_claims_on_payment_id"
    t.index ["reference"], name: "index_claims_on_reference", unique: true
    t.index ["submitted_at"], name: "index_claims_on_submitted_at"
  end

  create_table "decisions", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.integer "result"
    t.uuid "claim_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "notes"
    t.uuid "created_by_id"
    t.boolean "undone", default: false
    t.index ["claim_id"], name: "index_decisions_on_claim_id"
    t.index ["created_at"], name: "index_decisions_on_created_at"
    t.index ["created_by_id"], name: "index_decisions_on_created_by_id"
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

  create_table "dfe_sign_in_users", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "dfe_sign_in_id"
    t.string "given_name"
    t.string "family_name"
    t.string "email"
    t.string "organisation_name"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.string "role_codes", default: [], array: true
    t.index ["dfe_sign_in_id"], name: "index_dfe_sign_in_users_on_dfe_sign_in_id", unique: true
  end

  create_table "early_career_payments_eligibilities", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.boolean "nqt_in_academic_year_after_itt"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
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
    t.integer "has_uk_maths_or_physics_degree"
    t.integer "qts_award_year"
    t.boolean "employed_as_supply_teacher"
    t.boolean "has_entire_term_contract"
    t.boolean "employed_directly"
    t.boolean "subject_to_disciplinary_action"
    t.boolean "subject_to_formal_performance_action"
    t.integer "initial_teacher_training_subject"
    t.integer "initial_teacher_training_subject_specialism"
    t.index ["created_at"], name: "index_maths_and_physics_eligibilities_on_created_at"
    t.index ["current_school_id"], name: "index_maths_and_physics_eligibilities_on_current_school_id"
  end

  create_table "notes", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "body"
    t.uuid "claim_id"
    t.uuid "created_by_id"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["claim_id", "created_at"], name: "index_notes_on_claim_id_and_created_at", unique: true
    t.index ["claim_id"], name: "index_notes_on_claim_id"
    t.index ["created_by_id"], name: "index_notes_on_created_by_id"
  end

  create_table "payments", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
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
    t.decimal "gross_pay", precision: 7, scale: 2
    t.index ["created_at"], name: "index_payments_on_created_at"
    t.index ["payroll_run_id"], name: "index_payments_on_payroll_run_id"
  end

  create_table "payroll_runs", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "downloaded_at"
    t.uuid "created_by_id"
    t.uuid "downloaded_by_id"
    t.date "scheduled_payment_date"
    t.uuid "confirmation_report_uploaded_by_id"
    t.index ["confirmation_report_uploaded_by_id"], name: "index_payroll_runs_on_confirmation_report_uploaded_by_id"
    t.index ["created_at"], name: "index_payroll_runs_on_created_at"
    t.index ["created_by_id"], name: "index_payroll_runs_on_created_by_id"
    t.index ["downloaded_by_id"], name: "index_payroll_runs_on_downloaded_by_id"
    t.index ["updated_at"], name: "index_payroll_runs_on_updated_at"
  end

  create_table "policy_configurations", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "policy_type", null: false
    t.boolean "open_for_submissions", default: true, null: false
    t.string "availability_message"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "current_academic_year", limit: 9
    t.index ["created_at"], name: "index_policy_configurations_on_created_at"
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
    t.integer "statutory_high_age"
    t.string "phone_number", limit: 20
    t.index ["created_at"], name: "index_schools_on_created_at"
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
    t.index ["created_at"], name: "index_student_loans_eligibilities_on_created_at"
    t.index ["current_school_id"], name: "index_student_loans_eligibilities_on_current_school_id"
  end

  create_table "support_tickets", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "url", null: false
    t.uuid "claim_id"
    t.uuid "created_by_id"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["claim_id"], name: "index_support_tickets_on_claim_id"
    t.index ["created_by_id"], name: "index_support_tickets_on_created_by_id"
  end

  create_table "tasks", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "name"
    t.uuid "claim_id"
    t.uuid "created_by_id"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.boolean "passed"
    t.boolean "manual"
    t.index ["claim_id"], name: "index_tasks_on_claim_id"
    t.index ["created_by_id"], name: "index_tasks_on_created_by_id"
    t.index ["name", "claim_id"], name: "index_tasks_on_name_and_claim_id", unique: true
  end

  add_foreign_key "amendments", "claims"
  add_foreign_key "amendments", "dfe_sign_in_users", column: "created_by_id"
  add_foreign_key "amendments", "dfe_sign_in_users", column: "dfe_sign_in_users_id"
  add_foreign_key "claims", "payments"
  add_foreign_key "decisions", "dfe_sign_in_users", column: "created_by_id"
  add_foreign_key "maths_and_physics_eligibilities", "schools", column: "current_school_id"
  add_foreign_key "notes", "claims"
  add_foreign_key "notes", "dfe_sign_in_users", column: "created_by_id"
  add_foreign_key "payments", "payroll_runs"
  add_foreign_key "payroll_runs", "dfe_sign_in_users", column: "confirmation_report_uploaded_by_id"
  add_foreign_key "payroll_runs", "dfe_sign_in_users", column: "created_by_id"
  add_foreign_key "payroll_runs", "dfe_sign_in_users", column: "downloaded_by_id"
  add_foreign_key "schools", "local_authority_districts"
  add_foreign_key "student_loans_eligibilities", "schools", column: "claim_school_id"
  add_foreign_key "student_loans_eligibilities", "schools", column: "current_school_id"
  add_foreign_key "support_tickets", "claims"
  add_foreign_key "support_tickets", "dfe_sign_in_users", column: "created_by_id"
  add_foreign_key "tasks", "claims"
  add_foreign_key "tasks", "dfe_sign_in_users", column: "created_by_id"
end
