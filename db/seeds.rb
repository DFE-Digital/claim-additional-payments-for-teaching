# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rails db:seed command (or created alongside the database with db:setup).
#
# Examples:
#
#   movies = Movie.create([{ name: 'Star Wars' }, { name: 'Lord of the Rings' }])
#   Character.create(name: 'Luke', movie: movies.first)

if Rails.env.development? || ENV["ENVIRONMENT_NAME"].start_with?("review")
  Journeys::Configuration.create!(routing_name: Journeys::TeacherStudentLoanReimbursement::ROUTING_NAME, current_academic_year: AcademicYear.current)
  Journeys::Configuration.create!(routing_name: Journeys::AdditionalPaymentsForTeaching::ROUTING_NAME, current_academic_year: AcademicYear.current)
  Journeys::Configuration.create!(routing_name: Journeys::GetATeacherRelocationPayment::ROUTING_NAME, current_academic_year: AcademicYear.current)
  Journeys::Configuration.create!(routing_name: Journeys::FurtherEducationPayments::ROUTING_NAME, current_academic_year: AcademicYear.current)
  Journeys::Configuration.create!(routing_name: Journeys::FurtherEducationPayments::Provider::ROUTING_NAME, current_academic_year: AcademicYear.current)
  Journeys::Configuration.create!(routing_name: Journeys::EarlyYearsPayment::Provider::Start::ROUTING_NAME, current_academic_year: AcademicYear.current)
  Journeys::Configuration.create!(routing_name: Journeys::EarlyYearsPayment::Provider::Authenticated::ROUTING_NAME, current_academic_year: AcademicYear.current)
  Journeys::Configuration.create!(routing_name: Journeys::EarlyYearsPayment::Practitioner::ROUTING_NAME, current_academic_year: AcademicYear.current)

  ENV["FIXTURES_PATH"] = "spec/fixtures"
  ENV["FIXTURES"] = "local_authorities,local_authority_districts,schools"
  Rake::Task["db:fixtures:load"].invoke
end

if ENV["ENVIRONMENT_NAME"].start_with?("review")
  EligibleFeProvidersImporter.new(
    File.new(Rails.root.join("spec/fixtures/files/eligible_fe_providers.csv")),
    AcademicYear.current
  ).run

  SchoolDataImporterJob.perform_now if School.count < 100

  school = School.find_by!(ukprn: "10000796")

  100.times do
    claim = Claim.new(
      "address_line_1" => "t",
      "address_line_2" => "t",
      "address_line_3" => "t",
      "address_line_4" => "t",
      "postcode" => "te57 1ng",
      "date_of_birth" => Date.new(1970, 1, 1),
      "national_insurance_number" => "QQ111111C",
      "email_address" => "test@example.com",
      "bank_sort_code" => "309444",
      "bank_account_number" => "44444444",
      "payroll_gender" => "male",
      "first_name" => "TEST",
      "middle_name" => "",
      "surname" => "USER",
      "banking_name" => "t",
      "bank_or_building_society" => "personal_bank_account",
      "provide_mobile_number" => false,
      "email_verified" => true,
      "hmrc_bank_validation_succeeded" => false,
      "hmrc_bank_validation_responses" => [{"body" => "{\"error\":\"invalid_request\",\"error_description\":\"client_id is required\"}", "code" => 400}],
      "dqt_teacher_status" => {},
      "sent_one_time_password_at" => DateTime.now,
      "identity_confirmed_with_onelogin" => true,
      "logged_in_with_onelogin" => true,
      "onelogin_credentials" => nil,
      "onelogin_user_info" => {"email" => "test@example.com"},
      "onelogin_uid" => "12345",
      "onelogin_auth_at" => DateTime.now,
      "onelogin_idv_at" => DateTime.now,
      "onelogin_idv_first_name" => "TEST",
      "onelogin_idv_last_name" => "USER",
      "onelogin_idv_date_of_birth" => Date.new(1970, 1, 1),
      :academic_year => AcademicYear.current
    )

    eligibility = Policies::FurtherEducationPayments::Eligibility.new(
      "award_amount" => 0.6e4,
      "teacher_reference_number" => "1231231",
      "teaching_responsibilities" => true,
      "provision_search" => "Penistone Grammar School",
      "possible_school_id" => school.id,
      "school_id" => school.id,
      "contract_type" => "variable_hours",
      "fixed_term_full_year" => nil,
      "taught_at_least_one_term" => true,
      "teaching_hours_per_week" => "more_than_12",
      "teaching_hours_per_week_next_term" => "at_least_2_5",
      "further_education_teaching_start_year" => "2024",
      "subjects_taught" => ["building_construction"],
      "building_construction_courses" => ["level3_buildingconstruction_approved"],
      "chemistry_courses" => [],
      "computing_courses" => [],
      "early_years_courses" => [],
      "engineering_manufacturing_courses" => [],
      "maths_courses" => [],
      "physics_courses" => [],
      "hours_teaching_eligible_subjects" => true,
      "teaching_qualification" => "yes",
      "subject_to_formal_performance_action" => false,
      "subject_to_disciplinary_action" => false,
      "half_teaching_hours" => true,
      "verification" => {},
      "flagged_as_duplicate" => true,
      "provider_verification_email_last_sent_at" => nil,
      "provider_verification_chase_email_last_sent_at" => nil
    )

    claim.eligibility = eligibility

    claim.started_at = 1.hour.ago
    claim.submitted_at = Time.zone.now

    while Claim.exists?(reference: ref = Reference.new.to_s)
      ref = Reference.new.to_s
    end
    claim.reference = ref

    claim.save!
  end
end

if Rails.env.development?
  require "./lib/factory_helpers"

  class Seeds
    extend FactoryBot::Syntax::Methods

    FactoryHelpers.create_factory_registry
    FactoryHelpers.reset_factory_registry

    if ENV["SEED_ACADEMIC_YEAR"].nil?
      # use original project defaults
      create(:payroll_run, :confirmation_report_uploaded,
        claims_counts: {Policies::StudentLoans => 2, Policies::EarlyCareerPayments => 2, Policies::LevellingUpPremiumPayments => 2, [Policies::StudentLoans, Policies::EarlyCareerPayments] => 2, [Policies::StudentLoans, Policies::LevellingUpPremiumPayments] => 2},
        created_at: 3.months.ago - 10.days)
      create(:payroll_run, :confirmation_report_uploaded,
        claims_counts: {Policies::StudentLoans => 2, Policies::EarlyCareerPayments => 2, Policies::LevellingUpPremiumPayments => 2, [Policies::StudentLoans, Policies::EarlyCareerPayments] => 2, [Policies::StudentLoans, Policies::LevellingUpPremiumPayments] => 2},
        created_at: 2.months.ago - 5.days)
      create(:payroll_run, :confirmation_report_uploaded,
        claims_counts: {Policies::StudentLoans => 2, Policies::EarlyCareerPayments => 2, Policies::LevellingUpPremiumPayments => 2, [Policies::StudentLoans, Policies::EarlyCareerPayments] => 2, [Policies::StudentLoans, Policies::LevellingUpPremiumPayments] => 2},
        created_at: 1.months.ago - 3.days)

      Policies.all.each do |policy|
        create_list(:claim, 23, :approved, policy: policy)
        create_list(:claim, 8, :submitted, policy: policy)
        create_list(:claim, 2, :submitted, :bank_details_not_validated, policy: policy)
        create_list(:claim, 5, :rejected, policy: policy)
        create_list(:claim, 1, :unverified, policy: policy)
      end

      create(:school, :early_career_payments_eligible, :not_state_funded)

    # TODO: Remove this or configure for this and future years
    elsif ENV["SEED_ACADEMIC_YEAR"] == "2021"
      # This should probably be updated each year to:
      #  - reflect the reality of what is occuring in that years claim window
      #  - e.g. in 2021, M+P is not longer running
      #    There cannot be teachers claiming TSLR & ECP as the 2020/2021 Physics cohort is not eligible

      create(:payroll_run, :confirmation_report_uploaded,
        claims_counts: {Policies::StudentLoans => 10, Policies::EarlyCareerPayments => 15},
        created_at: 3.months.ago - 10.days)
      create(:payroll_run, :confirmation_report_uploaded,
        claims_counts: {Policies::StudentLoans => 8, Policies::EarlyCareerPayments => 25},
        created_at: 2.months.ago - 5.days)
      create(:payroll_run, :confirmation_report_uploaded,
        claims_counts: {Policies::StudentLoans => 2, Policies::EarlyCareerPayments => 10},
        created_at: 1.months.ago - 3.days)

      policy = Policies::StudentLoans
      create_list(:claim, 4, :approved, policy: policy)
      create_list(:claim, 1, :submitted, policy: policy)
      create_list(:claim, 1, :rejected, policy: policy)
      create_list(:claim, 1, :unverified, policy: policy)

      policy = Policies::EarlyCareerPayments
      create_list(:claim, 12, :approved, policy: policy)
      create_list(:claim, 1, :submitted, policy: policy)
      create_list(:claim, 1, :rejected, policy: policy)
      create_list(:claim, 1, :unverified, policy: policy)
    end
  end
end
