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

ActiveRecord::Schema[7.0].define(version: 2023_09_25_163438) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_trgm"
  enable_extension "pgcrypto"
  enable_extension "plpgsql"

  create_table "amendments", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "claim_id"
    t.text "notes"
    t.string "claim_changes"
    t.uuid "dfe_sign_in_users_id"
    t.uuid "created_by_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "personal_data_removed_at"
    t.index ["claim_id"], name: "index_amendments_on_claim_id"
    t.index ["created_by_id"], name: "index_amendments_on_created_by_id"
    t.index ["dfe_sign_in_users_id"], name: "index_amendments_on_dfe_sign_in_users_id"
  end

  create_table "claim_payments", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "claim_id"
    t.uuid "payment_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["claim_id", "payment_id"], name: "index_claim_payments_on_claim_id_and_payment_id", unique: true
    t.index ["claim_id"], name: "index_claim_payments_on_claim_id"
    t.index ["payment_id"], name: "index_claim_payments_on_payment_id"
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
    t.string "eligibility_type"
    t.uuid "eligibility_id"
    t.integer "payroll_gender"
    t.text "govuk_verify_fields", default: [], array: true
    t.string "first_name", limit: 100
    t.string "middle_name", limit: 100
    t.string "surname", limit: 100
    t.string "banking_name"
    t.string "building_society_roll_number"
    t.uuid "remove_column_payment_id"
    t.datetime "personal_data_removed_at"
    t.string "academic_year", limit: 9
    t.integer "bank_or_building_society"
    t.boolean "provide_mobile_number"
    t.string "mobile_number"
    t.boolean "postgraduate_masters_loan"
    t.boolean "postgraduate_doctoral_loan"
    t.boolean "email_verified", default: false
    t.boolean "has_masters_doctoral_loan"
    t.boolean "mobile_verified", default: false
    t.string "assigned_to_id"
    t.jsonb "policy_options_provided", default: []
    t.boolean "held", default: false
    t.boolean "hmrc_bank_validation_succeeded", default: false
    t.json "hmrc_bank_validation_responses", default: []
    t.index ["academic_year"], name: "index_claims_on_academic_year"
    t.index ["created_at"], name: "index_claims_on_created_at"
    t.index ["eligibility_type", "eligibility_id"], name: "index_claims_on_eligibility_type_and_eligibility_id"
    t.index ["held"], name: "index_claims_on_held"
    t.index ["reference"], name: "index_claims_on_reference", unique: true
    t.index ["remove_column_payment_id"], name: "index_claims_on_remove_column_payment_id"
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
    t.jsonb "rejected_reasons", default: {}
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
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "role_codes", default: [], array: true
    t.datetime "deleted_at"
    t.string "session_token"
    t.index ["deleted_at"], name: "index_dfe_sign_in_users_on_deleted_at"
    t.index ["dfe_sign_in_id"], name: "index_dfe_sign_in_users_on_dfe_sign_in_id", unique: true
    t.index ["session_token"], name: "index_dfe_sign_in_users_on_session_token", unique: true
  end

  create_table "early_career_payments_eligibilities", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.boolean "nqt_in_academic_year_after_itt"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "employed_as_supply_teacher"
    t.integer "qualification"
    t.boolean "has_entire_term_contract"
    t.boolean "employed_directly"
    t.boolean "subject_to_disciplinary_action"
    t.boolean "subject_to_formal_performance_action"
    t.integer "eligible_itt_subject"
    t.boolean "teaching_subject_now"
    t.string "itt_academic_year", limit: 9
    t.uuid "current_school_id"
    t.decimal "award_amount", precision: 7, scale: 2
    t.boolean "induction_completed"
    t.index ["current_school_id"], name: "index_early_career_payments_eligibilities_on_current_school_id"
  end

  create_table "file_uploads", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "uploaded_by_id"
    t.text "body"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "levelling_up_premium_payments_awards", force: :cascade do |t|
    t.string "academic_year", limit: 9, null: false
    t.integer "school_urn", null: false
    t.decimal "award_amount", precision: 7, scale: 2
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["academic_year", "school_urn"], name: "lupp_award_by_year_and_urn"
    t.index ["academic_year"], name: "lupp_award_by_year"
    t.index ["award_amount"], name: "lupp_award_by_amount"
    t.index ["school_urn"], name: "lupp_award_by_urn"
  end

  create_table "levelling_up_premium_payments_eligibilities", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "nqt_in_academic_year_after_itt"
    t.boolean "employed_as_supply_teacher"
    t.integer "qualification"
    t.boolean "has_entire_term_contract"
    t.boolean "employed_directly"
    t.boolean "subject_to_disciplinary_action"
    t.boolean "subject_to_formal_performance_action"
    t.integer "eligible_itt_subject"
    t.boolean "teaching_subject_now"
    t.string "itt_academic_year", limit: 9
    t.uuid "current_school_id"
    t.decimal "award_amount", precision: 7, scale: 2
    t.boolean "eligible_degree_subject"
    t.boolean "induction_completed"
    t.index ["current_school_id"], name: "index_lup_payments_eligibilities_on_current_school_id"
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
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "important"
    t.string "label"
    t.index ["claim_id"], name: "index_notes_on_claim_id"
    t.index ["created_by_id"], name: "index_notes_on_created_by_id"
    t.index ["label", "claim_id"], name: "index_notes_on_label_and_claim_id"
  end

  create_table "payment_confirmations", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "payroll_run_id"
    t.uuid "created_by_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["created_by_id"], name: "index_payment_confirmations_on_created_by_id"
    t.index ["payroll_run_id"], name: "index_payment_confirmations_on_payroll_run_id"
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
    t.decimal "postgraduate_loan_repayment", precision: 7, scale: 2
    t.uuid "confirmation_id"
    t.date "scheduled_payment_date"
    t.index ["confirmation_id"], name: "index_payments_on_confirmation_id"
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
    t.boolean "open_for_submissions", default: true, null: false
    t.string "availability_message"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "current_academic_year", limit: 9
    t.text "policy_types", default: [], array: true
    t.index ["created_at"], name: "index_policy_configurations_on_created_at"
  end

  create_table "reminders", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "full_name"
    t.string "email_address"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "email_verified", default: false
    t.datetime "email_sent_at"
    t.string "itt_academic_year", limit: 9
    t.string "itt_subject"
  end

  create_table "school_workforce_censuses", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "teacher_reference_number"
    t.string "subject_1"
    t.string "subject_2"
    t.string "subject_3"
    t.string "subject_4"
    t.string "subject_5"
    t.string "subject_6"
    t.string "subject_7"
    t.string "subject_8"
    t.string "subject_9"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "subject_10"
    t.string "subject_11"
    t.string "subject_12"
    t.string "subject_13"
    t.string "subject_14"
    t.string "subject_15"
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
    t.date "open_date"
    t.string "postcode_sanitised"
    t.index ["close_date"], name: "index_schools_on_close_date"
    t.index ["created_at"], name: "index_schools_on_created_at"
    t.index ["local_authority_district_id"], name: "index_schools_on_local_authority_district_id"
    t.index ["local_authority_id"], name: "index_schools_on_local_authority_id"
    t.index ["name"], name: "index_schools_on_name", opclass: :gin_trgm_ops, using: :gin
    t.index ["open_date"], name: "index_schools_on_open_date"
    t.index ["postcode_sanitised"], name: "index_schools_on_postcode_sanitised", opclass: :gin_trgm_ops, using: :gin
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
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["claim_id"], name: "index_support_tickets_on_claim_id"
    t.index ["created_by_id"], name: "index_support_tickets_on_created_by_id"
  end

  create_table "tasks", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "name"
    t.uuid "claim_id"
    t.uuid "created_by_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "passed"
    t.boolean "manual"
    t.integer "claim_verifier_match"
    t.index ["claim_id"], name: "index_tasks_on_claim_id"
    t.index ["created_by_id"], name: "index_tasks_on_created_by_id"
    t.index ["name", "claim_id"], name: "index_tasks_on_name_and_claim_id", unique: true
  end

  create_table "teachers_pensions_service", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "teacher_reference_number"
    t.datetime "start_date"
    t.datetime "end_date"
    t.integer "la_urn"
    t.integer "school_urn"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "gender_digit"
    t.string "nino"
    t.integer "employer_id"
    t.index ["employer_id"], name: "index_teachers_pensions_service_on_employer_id"
    t.index ["teacher_reference_number", "start_date"], name: "index_tps_data_on_teacher_reference_number_and_start_date", unique: true
    t.index ["teacher_reference_number"], name: "index_teachers_pensions_service_on_teacher_reference_number"
  end

  create_table "topups", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "claim_id"
    t.decimal "award_amount", precision: 7, scale: 2
    t.uuid "payment_id"
    t.uuid "dfe_sign_in_users_id"
    t.uuid "created_by_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["claim_id", "payment_id"], name: "index_topups_on_claim_id_and_payment_id", unique: true
    t.index ["claim_id"], name: "index_topups_on_claim_id"
    t.index ["created_by_id"], name: "index_topups_on_created_by_id"
    t.index ["dfe_sign_in_users_id"], name: "index_topups_on_dfe_sign_in_users_id"
    t.index ["payment_id"], name: "index_topups_on_payment_id"
  end

  add_foreign_key "amendments", "claims"
  add_foreign_key "amendments", "dfe_sign_in_users", column: "created_by_id"
  add_foreign_key "amendments", "dfe_sign_in_users", column: "dfe_sign_in_users_id"
  add_foreign_key "claim_payments", "claims"
  add_foreign_key "claim_payments", "payments"
  add_foreign_key "claims", "payments", column: "remove_column_payment_id"
  add_foreign_key "decisions", "dfe_sign_in_users", column: "created_by_id"
  add_foreign_key "early_career_payments_eligibilities", "schools", column: "current_school_id"
  add_foreign_key "levelling_up_premium_payments_eligibilities", "schools", column: "current_school_id"
  add_foreign_key "maths_and_physics_eligibilities", "schools", column: "current_school_id"
  add_foreign_key "notes", "claims"
  add_foreign_key "notes", "dfe_sign_in_users", column: "created_by_id"
  add_foreign_key "payment_confirmations", "dfe_sign_in_users", column: "created_by_id"
  add_foreign_key "payment_confirmations", "payroll_runs"
  add_foreign_key "payments", "payment_confirmations", column: "confirmation_id"
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
  add_foreign_key "topups", "claims"
  add_foreign_key "topups", "dfe_sign_in_users", column: "created_by_id"
  add_foreign_key "topups", "dfe_sign_in_users", column: "dfe_sign_in_users_id"
  add_foreign_key "topups", "payments"

  create_view "claim_decisions", sql_definition: <<-SQL
      WITH eligibilities AS (
           SELECT early_career_payments_eligibilities.id,
              early_career_payments_eligibilities.current_school_id AS school_id,
                  CASE early_career_payments_eligibilities.eligible_itt_subject
                      WHEN 0 THEN 'chemistry'::text
                      WHEN 1 THEN 'foreign languages'::text
                      WHEN 2 THEN 'maths'::text
                      WHEN 3 THEN 'physics'::text
                      WHEN 4 THEN 'none'::text
                      ELSE NULL::text
                  END AS subject
             FROM early_career_payments_eligibilities
          UNION ALL
           SELECT maths_and_physics_eligibilities.id,
              maths_and_physics_eligibilities.current_school_id AS school_id,
                  CASE maths_and_physics_eligibilities.initial_teacher_training_subject
                      WHEN 0 THEN 'maths'::text
                      WHEN 1 THEN 'physics'::text
                      WHEN 2 THEN 'science'::text
                      WHEN 3 THEN 'none'::text
                      ELSE NULL::text
                  END AS subject
             FROM maths_and_physics_eligibilities
          UNION ALL
           SELECT student_loans_eligibilities.id,
              student_loans_eligibilities.claim_school_id AS school_id,
                  CASE
                      WHEN (student_loans_eligibilities.biology_taught IS TRUE) THEN 'biology'::text
                      WHEN (student_loans_eligibilities.chemistry_taught IS TRUE) THEN 'chemistry'::text
                      WHEN (student_loans_eligibilities.computing_taught IS TRUE) THEN 'computing'::text
                      WHEN (student_loans_eligibilities.languages_taught IS TRUE) THEN 'languages'::text
                      WHEN (student_loans_eligibilities.physics_taught IS TRUE) THEN 'physics'::text
                      ELSE 'none'::text
                  END AS subject
             FROM student_loans_eligibilities
          )
   SELECT c.id AS application_id,
      d.created_at AS decision_date,
      c.teacher_reference_number AS trn,
          CASE d.result
              WHEN 0 THEN 'approved'::text
              WHEN 1 THEN 'rejected'::text
              ELSE NULL::text
          END AS application_decision,
          CASE c.eligibility_type
              WHEN 'EarlyCareerPayments::Eligibility'::text THEN 'early career payments'::text
              WHEN 'StudentLoans::Eligibility'::text THEN 'student loans'::text
              WHEN 'MathsAndPhysics::Eligibility'::text THEN 'maths and physics'::text
              ELSE NULL::text
          END AS application_policy,
      e.subject,
      s.name AS school_name,
      la.name AS local_authorities_name,
      lad.name AS local_authority_district_name,
      (date_part('year'::text, age(now(), (c.date_of_birth)::timestamp with time zone)))::integer AS claimant_age,
          CASE c.payroll_gender
              WHEN 0 THEN 'don''t know'::text
              WHEN 1 THEN 'female'::text
              WHEN 2 THEN 'male'::text
              ELSE NULL::text
          END AS claimant_gender,
      c.academic_year AS claimant_year_qualified
     FROM decisions d,
      claims c,
      schools s,
      eligibilities e,
      local_authorities la,
      local_authority_districts lad
    WHERE ((d.claim_id = c.id) AND (c.eligibility_id = e.id) AND (e.school_id = s.id) AND (s.local_authority_id = la.id) AND (s.local_authority_district_id = lad.id));
  SQL
  create_view "claim_stats", materialized: true, sql_definition: <<-SQL
      SELECT c.id AS claim_id,
          CASE c.eligibility_type
              WHEN 'EarlyCareerPayments::Eligibility'::text THEN 'early career payments'::text
              WHEN 'StudentLoans::Eligibility'::text THEN 'student loans'::text
              WHEN 'MathsAndPhysics::Eligibility'::text THEN 'maths and physics'::text
              ELSE NULL::text
          END AS policy,
      c.created_at AS claim_started_at,
      c.submitted_at AS claim_submitted_at,
      d.created_at AS decision_made_at,
          CASE d.result
              WHEN 0 THEN 'accepted'::text
              WHEN 1 THEN 'rejected'::text
              ELSE NULL::text
          END AS result,
          CASE c.submitted_at
              WHEN NULL::timestamp without time zone THEN NULL::numeric
              ELSE EXTRACT(epoch FROM (c.submitted_at - c.created_at))
          END AS submission_length,
          CASE d.created_at
              WHEN NULL::timestamp without time zone THEN NULL::numeric
              ELSE EXTRACT(epoch FROM (d.created_at - c.submitted_at))
          END AS decision_length
     FROM (decisions d
       RIGHT JOIN claims c ON ((c.id = d.claim_id)))
    WHERE (c.created_at > make_timestamptz(2021, 9, 6, 0, 0, (0)::double precision));
  SQL
end
