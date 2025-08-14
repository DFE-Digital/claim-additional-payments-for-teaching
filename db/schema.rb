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

ActiveRecord::Schema[8.0].define(version: 2025_08_14_140558) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "citext"
  enable_extension "pg_catalog.plpgsql"
  enable_extension "pg_trgm"
  enable_extension "pgcrypto"

  create_table "amendments", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "claim_id"
    t.text "notes"
    t.string "claim_changes"
    t.uuid "dfe_sign_in_users_id"
    t.uuid "created_by_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "personal_data_removed_at", precision: nil
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
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.string "address_line_1", limit: 100
    t.string "address_line_2", limit: 100
    t.string "address_line_3", limit: 100
    t.string "address_line_4", limit: 100
    t.string "postcode", limit: 11
    t.date "date_of_birth"
    t.string "column_to_remove_teacher_reference_number", limit: 11
    t.string "national_insurance_number", limit: 9
    t.string "email_address", limit: 256
    t.string "bank_sort_code", limit: 6
    t.string "bank_account_number", limit: 8
    t.datetime "submitted_at", precision: nil
    t.string "reference", limit: 8, null: false
    t.boolean "has_student_loan"
    t.integer "student_loan_country"
    t.integer "student_loan_courses"
    t.integer "student_loan_start_date"
    t.string "student_loan_plan"
    t.string "eligibility_type"
    t.uuid "eligibility_id"
    t.integer "payroll_gender"
    t.text "govuk_verify_fields", default: [], array: true
    t.string "first_name", limit: 100
    t.string "middle_name", limit: 100
    t.string "surname", limit: 100
    t.string "banking_name"
    t.string "building_society_roll_number"
    t.datetime "personal_data_removed_at", precision: nil
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
    t.boolean "logged_in_with_tid"
    t.boolean "qa_required", default: false
    t.datetime "qa_completed_at"
    t.boolean "details_check"
    t.jsonb "teacher_id_user_info", default: {}
    t.boolean "email_address_check"
    t.string "mobile_check"
    t.jsonb "dqt_teacher_status"
    t.boolean "qualifications_details_check"
    t.boolean "submitted_using_slc_data", default: false
    t.datetime "sent_one_time_password_at"
    t.uuid "journeys_session_id"
    t.boolean "identity_confirmed_with_onelogin"
    t.boolean "logged_in_with_onelogin"
    t.jsonb "onelogin_credentials", default: {}
    t.jsonb "onelogin_user_info", default: {}
    t.string "paye_reference"
    t.citext "practitioner_email_address"
    t.string "provider_contact_name"
    t.text "onelogin_uid"
    t.datetime "onelogin_auth_at"
    t.datetime "onelogin_idv_at"
    t.text "onelogin_idv_first_name"
    t.text "onelogin_idv_last_name"
    t.date "onelogin_idv_date_of_birth"
    t.datetime "started_at", precision: nil, null: false
    t.datetime "verified_at"
    t.text "onelogin_idv_full_name"
    t.text "onelogin_idv_return_codes", array: true
    t.text "policy", null: false
    t.datetime "retained_personal_data_removed_at"
    t.index ["academic_year"], name: "index_claims_on_academic_year"
    t.index ["created_at"], name: "index_claims_on_created_at"
    t.index ["eligibility_type", "eligibility_id"], name: "index_claims_on_eligibility_type_and_eligibility_id"
    t.index ["held"], name: "index_claims_on_held"
    t.index ["journeys_session_id"], name: "index_claims_on_journeys_session_id"
    t.index ["policy"], name: "index_claims_on_policy"
    t.index ["qa_required", "qa_completed_at"], name: "index_claims_on_qa_required_and_qa_completed_at", where: "qa_required"
    t.index ["reference"], name: "index_claims_on_reference", unique: true
    t.index ["submitted_at"], name: "index_claims_on_submitted_at"
  end

  create_table "decisions", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "claim_id"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.text "notes"
    t.uuid "created_by_id"
    t.boolean "undone", default: false
    t.jsonb "rejected_reasons", default: {}
    t.boolean "approved", null: false
    t.index ["claim_id"], name: "index_decisions_on_claim_id"
    t.index ["created_at"], name: "index_decisions_on_created_at"
    t.index ["created_by_id"], name: "index_decisions_on_created_by_id"
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
    t.datetime "deleted_at", precision: nil
    t.string "session_token"
    t.string "current_organisation_ukprn"
    t.text "user_type"
    t.index ["deleted_at"], name: "index_dfe_sign_in_users_on_deleted_at"
    t.index ["dfe_sign_in_id", "user_type"], name: "index_dfe_sign_in_users_on_dfe_sign_in_id_and_user_type", unique: true
    t.index ["session_token"], name: "index_dfe_sign_in_users_on_session_token", unique: true
    t.index ["user_type"], name: "index_dfe_sign_in_users_on_user_type"
  end

  create_table "dqt_higher_education_qualifications", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "teacher_reference_number", limit: 11, null: false
    t.date "date_of_birth", null: false
    t.string "national_insurance_number", limit: 9
    t.string "subject_code", null: false
    t.string "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["teacher_reference_number", "date_of_birth", "subject_code"], name: "idx_on_teacher_reference_number_date_of_birth_subje_bba03d8c18", unique: true
    t.index ["teacher_reference_number", "date_of_birth"], name: "idx_on_teacher_reference_number_date_of_birth_f789775ba6"
  end

  create_table "early_career_payments_eligibilities", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.boolean "nqt_in_academic_year_after_itt"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "employed_as_supply_teacher"
    t.boolean "has_entire_term_contract"
    t.boolean "employed_directly"
    t.boolean "subject_to_disciplinary_action"
    t.boolean "subject_to_formal_performance_action"
    t.boolean "teaching_subject_now"
    t.string "itt_academic_year", limit: 9
    t.uuid "current_school_id"
    t.decimal "award_amount", precision: 7, scale: 2
    t.boolean "induction_completed"
    t.boolean "school_somewhere_else"
    t.string "teacher_reference_number", limit: 11
    t.string "qualification"
    t.string "eligible_itt_subject"
    t.index ["current_school_id"], name: "index_early_career_payments_eligibilities_on_current_school_id"
    t.index ["teacher_reference_number"], name: "index_ecp_eligibility_trn"
  end

  create_table "early_years_payment_eligibilities", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "nursery_urn"
    t.date "start_date"
    t.boolean "child_facing_confirmation_given"
    t.boolean "returning_within_6_months"
    t.datetime "provider_claim_submitted_at"
    t.datetime "practitioner_claim_started_at"
    t.string "provider_email_address"
    t.boolean "returner_worked_with_children"
    t.string "returner_contract_type"
    t.decimal "award_amount", precision: 7, scale: 2
    t.string "practitioner_first_name"
    t.string "practitioner_surname"
  end

  create_table "eligible_ey_providers", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "nursery_name"
    t.string "urn"
    t.uuid "local_authority_id", null: false
    t.string "nursery_address"
    t.citext "primary_key_contact_email_address"
    t.citext "secondary_contact_email_address"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.uuid "file_upload_id"
    t.index ["file_upload_id"], name: "index_eligible_ey_providers_on_file_upload_id"
    t.index ["local_authority_id"], name: "index_eligible_ey_providers_on_local_authority_id"
    t.index ["primary_key_contact_email_address"], name: "index_eligible_ey_providers_on_primary_contact_email_address"
    t.index ["secondary_contact_email_address"], name: "index_eligible_ey_providers_on_secondary_contact_email_address"
    t.index ["urn", "file_upload_id"], name: "index_eligible_ey_providers_on_urn_and_file_upload_id", unique: true
  end

  create_table "eligible_fe_providers", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.integer "ukprn", null: false
    t.text "academic_year", null: false
    t.decimal "max_award_amount", precision: 7, scale: 2
    t.decimal "lower_award_amount", precision: 7, scale: 2
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "primary_key_contact_email_address"
    t.uuid "file_upload_id"
    t.index ["academic_year", "ukprn", "file_upload_id"], name: "idx_on_academic_year_ukprn_file_upload_id_d31aaa765c", unique: true
    t.index ["file_upload_id"], name: "index_eligible_fe_providers_on_file_upload_id"
  end

  create_table "feature_flags", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.text "name", null: false
    t.boolean "enabled", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_feature_flags_on_name", unique: true
  end

  create_table "file_downloads", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "downloaded_by_id"
    t.text "body"
    t.string "filename"
    t.string "content_type"
    t.string "source_data_model"
    t.string "source_data_model_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "file_uploads", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "uploaded_by_id"
    t.text "body"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "target_data_model"
    t.datetime "completed_processing_at"
    t.string "academic_year", limit: 9
  end

  create_table "further_education_payments_eligibilities", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.decimal "award_amount", precision: 7, scale: 2
    t.text "teacher_reference_number"
    t.boolean "teaching_responsibilities"
    t.text "provision_search"
    t.uuid "possible_school_id"
    t.uuid "school_id"
    t.text "contract_type"
    t.boolean "fixed_term_full_year"
    t.boolean "taught_at_least_one_term"
    t.text "teaching_hours_per_week"
    t.text "teaching_hours_per_week_next_term"
    t.text "further_education_teaching_start_year"
    t.jsonb "subjects_taught", default: []
    t.jsonb "building_construction_courses", default: []
    t.jsonb "chemistry_courses", default: []
    t.jsonb "computing_courses", default: []
    t.jsonb "early_years_courses", default: []
    t.jsonb "engineering_manufacturing_courses", default: []
    t.jsonb "maths_courses", default: []
    t.jsonb "physics_courses", default: []
    t.boolean "hours_teaching_eligible_subjects"
    t.text "teaching_qualification"
    t.boolean "subject_to_formal_performance_action"
    t.boolean "subject_to_disciplinary_action"
    t.boolean "half_teaching_hours"
    t.jsonb "verification", default: {}
    t.boolean "flagged_as_duplicate", default: false
    t.datetime "provider_verification_email_last_sent_at"
    t.datetime "provider_verification_chase_email_last_sent_at"
    t.integer "provider_verification_email_count", default: 0
    t.date "claimant_date_of_birth"
    t.string "claimant_postcode"
    t.string "claimant_national_insurance_number"
    t.boolean "claimant_valid_passport"
    t.string "claimant_passport_number"
    t.datetime "claimant_identity_verified_at"
    t.boolean "valid_passport"
    t.text "passport_number"
    t.boolean "provider_verification_teaching_responsibilities"
    t.boolean "provider_verification_in_first_five_years"
    t.string "provider_verification_teaching_qualification"
    t.string "provider_verification_contract_type"
    t.boolean "provider_verification_contract_covers_full_academic_year"
    t.boolean "provider_verification_taught_at_least_one_academic_term"
    t.boolean "provider_verification_performance_measures"
    t.boolean "provider_verification_disciplinary_action"
    t.string "provider_verification_teaching_hours_per_week"
    t.boolean "provider_verification_half_teaching_hours"
    t.boolean "provider_verification_subjects_taught"
    t.boolean "provider_verification_declaration"
    t.datetime "provider_verification_completed_at", precision: nil
    t.uuid "provider_verification_verified_by_id"
    t.uuid "provider_assigned_to_id"
    t.datetime "provider_verification_started_at"
    t.boolean "provider_verification_timetabled_teaching_hours"
    t.jsonb "provider_verification_actual_subjects_taught", default: []
    t.jsonb "provider_verification_building_construction_courses", default: []
    t.jsonb "provider_verification_chemistry_courses", default: []
    t.jsonb "provider_verification_computing_courses", default: []
    t.jsonb "provider_verification_early_years_courses", default: []
    t.jsonb "provider_verification_engineering_manufacturing_courses", default: []
    t.jsonb "provider_verification_maths_courses", default: []
    t.jsonb "provider_verification_physics_courses", default: []
    t.boolean "provider_verification_half_timetabled_teaching_time"
    t.citext "work_email"
    t.boolean "work_email_verified"
    t.index ["possible_school_id"], name: "index_fe_payments_eligibilities_on_possible_school_id"
    t.index ["provider_assigned_to_id"], name: "idx_on_provider_assigned_to_id_5db250f0fe"
    t.index ["provider_verification_verified_by_id"], name: "idx_on_provider_verification_verified_by_id_c38aef7b6c"
    t.index ["school_id"], name: "index_fe_payments_eligibilities_on_school_id"
  end

  create_table "international_relocation_payments_eligibilities", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "application_route"
    t.boolean "state_funded_secondary_school"
    t.boolean "one_year"
    t.date "start_date"
    t.string "subject"
    t.string "visa_type"
    t.date "date_of_entry"
    t.string "nationality"
    t.string "passport_number"
    t.string "school_headteacher_name"
    t.uuid "current_school_id"
    t.decimal "award_amount", precision: 7, scale: 2
    t.boolean "changed_workplace_or_new_contract"
    t.text "previous_year_claim_ids", default: [], array: true
    t.boolean "breaks_in_employment"
    t.jsonb "employment_history", default: []
    t.index ["current_school_id"], name: "index_irb_eligibilities_on_current_school_id"
  end

  create_table "journey_configurations", primary_key: "routing_name", id: :string, force: :cascade do |t|
    t.boolean "open_for_submissions", default: true, null: false
    t.string "availability_message"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.string "current_academic_year", limit: 9
    t.boolean "teacher_id_enabled", default: true
  end

  create_table "journeys_service_access_codes", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "code", null: false
    t.string "journey", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "used", default: false, null: false
    t.index ["code"], name: "index_journeys_service_access_codes_on_code", unique: true
  end

  create_table "journeys_sessions", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.jsonb "answers", default: {}
    t.string "journey", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
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
    t.uuid "file_upload_id"
    t.index ["created_by_id"], name: "index_payment_confirmations_on_created_by_id"
    t.index ["file_upload_id"], name: "index_payment_confirmations_on_file_upload_id"
    t.index ["payroll_run_id"], name: "index_payment_confirmations_on_payroll_run_id"
  end

  create_table "payments", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "payroll_run_id"
    t.decimal "award_amount", precision: 7, scale: 2
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
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
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.datetime "downloaded_at", precision: nil
    t.uuid "created_by_id"
    t.uuid "downloaded_by_id"
    t.date "scheduled_payment_date"
    t.uuid "confirmation_report_uploaded_by_id"
    t.string "status", default: "pending", null: false
    t.index ["confirmation_report_uploaded_by_id"], name: "index_payroll_runs_on_confirmation_report_uploaded_by_id"
    t.index ["created_at"], name: "index_payroll_runs_on_created_at"
    t.index ["created_by_id"], name: "index_payroll_runs_on_created_by_id"
    t.index ["downloaded_by_id"], name: "index_payroll_runs_on_downloaded_by_id"
    t.index ["updated_at"], name: "index_payroll_runs_on_updated_at"
  end

  create_table "reminders", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "full_name"
    t.string "email_address"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "email_verified", default: false
    t.datetime "email_sent_at", precision: nil
    t.string "itt_academic_year", limit: 9
    t.string "itt_subject"
    t.text "journey_class", null: false
    t.datetime "deleted_at"
    t.index ["journey_class"], name: "index_reminders_on_journey_class"
  end

  create_table "reports", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "name"
    t.text "csv"
    t.integer "number_of_rows"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "risk_indicators", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "field", null: false
    t.string "value", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["field", "value"], name: "index_risk_indicators_on_field_and_value", unique: true
  end

  create_table "school_workforce_censuses", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "teacher_reference_number"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "school_urn"
    t.string "contract_agreement_type"
    t.float "totfte"
    t.string "subject_description_sfr"
    t.string "general_subject_code"
    t.integer "hours_taught"
    t.index ["teacher_reference_number"], name: "index_school_workforce_censuses_on_teacher_reference_number"
  end

  create_table "schools", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.integer "urn", null: false
    t.string "name", null: false
    t.string "street"
    t.string "locality"
    t.string "town"
    t.string "county"
    t.string "postcode"
    t.uuid "local_authority_id"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.uuid "local_authority_district_id"
    t.date "close_date"
    t.integer "establishment_number"
    t.integer "statutory_high_age"
    t.string "phone_number", limit: 20
    t.date "open_date"
    t.string "postcode_sanitised"
    t.text "ukprn"
    t.string "phase", null: false
    t.string "school_type_group", null: false
    t.string "school_type", null: false
    t.index ["close_date"], name: "index_schools_on_close_date"
    t.index ["created_at"], name: "index_schools_on_created_at"
    t.index ["local_authority_district_id"], name: "index_schools_on_local_authority_district_id"
    t.index ["local_authority_id"], name: "index_schools_on_local_authority_id"
    t.index ["name"], name: "index_schools_on_name", opclass: :gin_trgm_ops, using: :gin
    t.index ["open_date"], name: "index_schools_on_open_date"
    t.index ["postcode_sanitised"], name: "index_schools_on_postcode_sanitised", opclass: :gin_trgm_ops, using: :gin
    t.index ["ukprn"], name: "index_schools_on_ukprn"
    t.index ["urn"], name: "index_schools_on_urn", unique: true
  end

  create_table "solid_queue_blocked_executions", force: :cascade do |t|
    t.bigint "job_id", null: false
    t.string "queue_name", null: false
    t.integer "priority", default: 0, null: false
    t.string "concurrency_key", null: false
    t.datetime "expires_at", null: false
    t.datetime "created_at", null: false
    t.index ["concurrency_key", "priority", "job_id"], name: "index_solid_queue_blocked_executions_for_release"
    t.index ["expires_at", "concurrency_key"], name: "index_solid_queue_blocked_executions_for_maintenance"
    t.index ["job_id"], name: "index_solid_queue_blocked_executions_on_job_id", unique: true
  end

  create_table "solid_queue_claimed_executions", force: :cascade do |t|
    t.bigint "job_id", null: false
    t.bigint "process_id"
    t.datetime "created_at", null: false
    t.index ["job_id"], name: "index_solid_queue_claimed_executions_on_job_id", unique: true
    t.index ["process_id", "job_id"], name: "index_solid_queue_claimed_executions_on_process_id_and_job_id"
  end

  create_table "solid_queue_failed_executions", force: :cascade do |t|
    t.bigint "job_id", null: false
    t.text "error"
    t.datetime "created_at", null: false
    t.index ["job_id"], name: "index_solid_queue_failed_executions_on_job_id", unique: true
  end

  create_table "solid_queue_jobs", force: :cascade do |t|
    t.string "queue_name", null: false
    t.string "class_name", null: false
    t.text "arguments"
    t.integer "priority", default: 0, null: false
    t.string "active_job_id"
    t.datetime "scheduled_at"
    t.datetime "finished_at"
    t.string "concurrency_key"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["active_job_id"], name: "index_solid_queue_jobs_on_active_job_id"
    t.index ["class_name"], name: "index_solid_queue_jobs_on_class_name"
    t.index ["finished_at"], name: "index_solid_queue_jobs_on_finished_at"
    t.index ["queue_name", "finished_at"], name: "index_solid_queue_jobs_for_filtering"
    t.index ["scheduled_at", "finished_at"], name: "index_solid_queue_jobs_for_alerting"
  end

  create_table "solid_queue_pauses", force: :cascade do |t|
    t.string "queue_name", null: false
    t.datetime "created_at", null: false
    t.index ["queue_name"], name: "index_solid_queue_pauses_on_queue_name", unique: true
  end

  create_table "solid_queue_processes", force: :cascade do |t|
    t.string "kind", null: false
    t.datetime "last_heartbeat_at", null: false
    t.bigint "supervisor_id"
    t.integer "pid", null: false
    t.string "hostname"
    t.text "metadata"
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.index ["last_heartbeat_at"], name: "index_solid_queue_processes_on_last_heartbeat_at"
    t.index ["name", "supervisor_id"], name: "index_solid_queue_processes_on_name_and_supervisor_id", unique: true
    t.index ["supervisor_id"], name: "index_solid_queue_processes_on_supervisor_id"
  end

  create_table "solid_queue_ready_executions", force: :cascade do |t|
    t.bigint "job_id", null: false
    t.string "queue_name", null: false
    t.integer "priority", default: 0, null: false
    t.datetime "created_at", null: false
    t.index ["job_id"], name: "index_solid_queue_ready_executions_on_job_id", unique: true
    t.index ["priority", "job_id"], name: "index_solid_queue_poll_all"
    t.index ["queue_name", "priority", "job_id"], name: "index_solid_queue_poll_by_queue"
  end

  create_table "solid_queue_recurring_executions", force: :cascade do |t|
    t.bigint "job_id", null: false
    t.string "task_key", null: false
    t.datetime "run_at", null: false
    t.datetime "created_at", null: false
    t.index ["job_id"], name: "index_solid_queue_recurring_executions_on_job_id", unique: true
    t.index ["task_key", "run_at"], name: "index_solid_queue_recurring_executions_on_task_key_and_run_at", unique: true
  end

  create_table "solid_queue_recurring_tasks", force: :cascade do |t|
    t.string "key", null: false
    t.string "schedule", null: false
    t.string "command", limit: 2048
    t.string "class_name"
    t.text "arguments"
    t.string "queue_name"
    t.integer "priority", default: 0
    t.boolean "static", default: true, null: false
    t.text "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["key"], name: "index_solid_queue_recurring_tasks_on_key", unique: true
    t.index ["static"], name: "index_solid_queue_recurring_tasks_on_static"
  end

  create_table "solid_queue_scheduled_executions", force: :cascade do |t|
    t.bigint "job_id", null: false
    t.string "queue_name", null: false
    t.integer "priority", default: 0, null: false
    t.datetime "scheduled_at", null: false
    t.datetime "created_at", null: false
    t.index ["job_id"], name: "index_solid_queue_scheduled_executions_on_job_id", unique: true
    t.index ["scheduled_at", "priority", "job_id"], name: "index_solid_queue_dispatch_all"
  end

  create_table "solid_queue_semaphores", force: :cascade do |t|
    t.string "key", null: false
    t.integer "value", default: 1, null: false
    t.datetime "expires_at", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["expires_at"], name: "index_solid_queue_semaphores_on_expires_at"
    t.index ["key", "value"], name: "index_solid_queue_semaphores_on_key_and_value"
    t.index ["key"], name: "index_solid_queue_semaphores_on_key", unique: true
  end

  create_table "stats", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.text "one_login_return_code"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "type"
  end

  create_table "student_loans_data", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "claim_reference"
    t.string "nino"
    t.string "full_name"
    t.date "date_of_birth"
    t.string "policy_name"
    t.integer "no_of_plans_currently_repaying"
    t.integer "plan_type_of_deduction"
    t.float "amount"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["claim_reference"], name: "index_student_loans_data_on_claim_reference"
    t.index ["nino"], name: "index_student_loans_data_on_nino"
  end

  create_table "student_loans_eligibilities", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.uuid "claim_school_id"
    t.uuid "current_school_id"
    t.boolean "biology_taught"
    t.boolean "chemistry_taught"
    t.boolean "computing_taught"
    t.boolean "languages_taught"
    t.boolean "physics_taught"
    t.boolean "taught_eligible_subjects"
    t.decimal "student_loan_repayment_amount", precision: 7, scale: 2
    t.boolean "had_leadership_position"
    t.boolean "mostly_performed_leadership_duties"
    t.boolean "claim_school_somewhere_else"
    t.string "teacher_reference_number", limit: 11
    t.string "qts_award_year"
    t.string "employment_status"
    t.decimal "award_amount", precision: 7, scale: 2
    t.index ["claim_school_id"], name: "index_student_loans_eligibilities_on_claim_school_id"
    t.index ["created_at"], name: "index_student_loans_eligibilities_on_created_at"
    t.index ["current_school_id"], name: "index_student_loans_eligibilities_on_current_school_id"
    t.index ["teacher_reference_number"], name: "index_sl_eligibility_trn"
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

  create_table "targeted_retention_incentive_payments_awards", force: :cascade do |t|
    t.string "academic_year", limit: 9, null: false
    t.integer "school_urn", null: false
    t.decimal "award_amount", precision: 7, scale: 2
    t.uuid "file_upload_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["academic_year", "school_urn", "file_upload_id"], name: "idx_on_academic_year_school_urn_file_upload_id_e22f377ca3"
    t.index ["academic_year"], name: "idx_on_academic_year_d488a0f13b"
    t.index ["file_upload_id"], name: "idx_on_file_upload_id_f03e7df6df"
    t.index ["school_urn"], name: "idx_on_school_urn_4cd86bf61e"
  end

  create_table "targeted_retention_incentive_payments_eligibilities", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.boolean "nqt_in_academic_year_after_itt"
    t.boolean "employed_as_supply_teacher"
    t.boolean "has_entire_term_contract"
    t.boolean "employed_directly"
    t.boolean "subject_to_disciplinary_action"
    t.boolean "subject_to_formal_performance_action"
    t.boolean "teaching_subject_now"
    t.string "itt_academic_year", limit: 9
    t.uuid "current_school_id"
    t.decimal "award_amount", precision: 7, scale: 2
    t.boolean "eligible_degree_subject"
    t.boolean "induction_completed"
    t.boolean "school_somewhere_else"
    t.string "teacher_reference_number", limit: 11
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "qualification"
    t.string "eligible_itt_subject"
    t.index ["current_school_id"], name: "idx_on_current_school_id_a8a77a93bf"
    t.index ["teacher_reference_number"], name: "idx_on_teacher_reference_number_d349ded5d7"
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
    t.text "reason"
    t.jsonb "data"
    t.index ["claim_id"], name: "index_tasks_on_claim_id"
    t.index ["created_by_id"], name: "index_tasks_on_created_by_id"
    t.index ["name", "claim_id"], name: "index_tasks_on_name_and_claim_id", unique: true
  end

  create_table "teachers_pensions_service", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "teacher_reference_number"
    t.datetime "start_date", precision: nil
    t.datetime "end_date", precision: nil
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
  add_foreign_key "claims", "journeys_sessions"
  add_foreign_key "decisions", "dfe_sign_in_users", column: "created_by_id"
  add_foreign_key "early_career_payments_eligibilities", "schools", column: "current_school_id"
  add_foreign_key "eligible_ey_providers", "file_uploads"
  add_foreign_key "eligible_ey_providers", "local_authorities"
  add_foreign_key "eligible_fe_providers", "file_uploads"
  add_foreign_key "further_education_payments_eligibilities", "dfe_sign_in_users", column: "provider_assigned_to_id"
  add_foreign_key "further_education_payments_eligibilities", "dfe_sign_in_users", column: "provider_verification_verified_by_id"
  add_foreign_key "further_education_payments_eligibilities", "schools"
  add_foreign_key "further_education_payments_eligibilities", "schools", column: "possible_school_id"
  add_foreign_key "international_relocation_payments_eligibilities", "schools", column: "current_school_id"
  add_foreign_key "notes", "claims"
  add_foreign_key "notes", "dfe_sign_in_users", column: "created_by_id"
  add_foreign_key "payment_confirmations", "dfe_sign_in_users", column: "created_by_id"
  add_foreign_key "payment_confirmations", "file_uploads"
  add_foreign_key "payment_confirmations", "payroll_runs"
  add_foreign_key "payments", "payment_confirmations", column: "confirmation_id"
  add_foreign_key "payments", "payroll_runs"
  add_foreign_key "payroll_runs", "dfe_sign_in_users", column: "confirmation_report_uploaded_by_id"
  add_foreign_key "payroll_runs", "dfe_sign_in_users", column: "created_by_id"
  add_foreign_key "payroll_runs", "dfe_sign_in_users", column: "downloaded_by_id"
  add_foreign_key "schools", "local_authority_districts"
  add_foreign_key "solid_queue_blocked_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_claimed_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_failed_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_ready_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_recurring_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_scheduled_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "student_loans_eligibilities", "schools", column: "claim_school_id"
  add_foreign_key "student_loans_eligibilities", "schools", column: "current_school_id"
  add_foreign_key "support_tickets", "claims"
  add_foreign_key "support_tickets", "dfe_sign_in_users", column: "created_by_id"
  add_foreign_key "targeted_retention_incentive_payments_awards", "file_uploads"
  add_foreign_key "tasks", "claims"
  add_foreign_key "tasks", "dfe_sign_in_users", column: "created_by_id"
  add_foreign_key "topups", "claims"
  add_foreign_key "topups", "dfe_sign_in_users", column: "created_by_id"
  add_foreign_key "topups", "dfe_sign_in_users", column: "dfe_sign_in_users_id"
  add_foreign_key "topups", "payments"
end
