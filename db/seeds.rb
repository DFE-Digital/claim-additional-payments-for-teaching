# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rails db:seed command (or created alongside the database with db:setup).
#
# Examples:
#
#   movies = Movie.create([{ name: 'Star Wars' }, { name: 'Lord of the Rings' }])
#   Character.create(name: 'Luke', movie: movies.first)

require "faker"
Faker::Config.locale = "en-GB"

if Rails.env.development? || ENV["ENVIRONMENT_NAME"].start_with?("review")
  Journeys::Configuration.create!(routing_name: Journeys::TeacherStudentLoanReimbursement::ROUTING_NAME, current_academic_year: AcademicYear.current)
  Journeys::Configuration.create!(routing_name: Journeys::TargetedRetentionIncentivePayments::ROUTING_NAME, current_academic_year: AcademicYear.current)
  Journeys::Configuration.create!(routing_name: Journeys::GetATeacherRelocationPayment::ROUTING_NAME, current_academic_year: AcademicYear.current)
  Journeys::Configuration.create!(routing_name: Journeys::FurtherEducationPayments::ROUTING_NAME, current_academic_year: AcademicYear.current)
  Journeys::Configuration.create!(routing_name: Journeys::FurtherEducationPayments::Provider::ROUTING_NAME, current_academic_year: AcademicYear.current)
  Journeys::Configuration.create!(routing_name: Journeys::EarlyYearsPayment::Provider::Start::ROUTING_NAME, current_academic_year: AcademicYear.current)
  Journeys::Configuration.create!(routing_name: Journeys::EarlyYearsPayment::Provider::Authenticated::ROUTING_NAME, current_academic_year: AcademicYear.current)
  Journeys::Configuration.create!(routing_name: Journeys::EarlyYearsPayment::Practitioner::ROUTING_NAME, current_academic_year: AcademicYear.current)

  FeatureFlag.enable!(:provider_dashboard)

  ENV["FIXTURES_PATH"] = "spec/fixtures"
  ENV["FIXTURES"] = "local_authorities,local_authority_districts,schools"
  Rake::Task["db:fixtures:load"].invoke
end

if Rails.env.development?
  class Seeds
    extend FactoryBot::Syntax::Methods

    if ENV["SEED_ACADEMIC_YEAR"].nil?
      # use original project defaults
      create(:payroll_run, :confirmation_report_uploaded,
        claims_counts: {Policies::StudentLoans => 2, Policies::EarlyCareerPayments => 2, Policies::TargetedRetentionIncentivePayments => 2, [Policies::StudentLoans, Policies::EarlyCareerPayments] => 2, [Policies::StudentLoans, Policies::TargetedRetentionIncentivePayments] => 2},
        created_at: 3.months.ago - 10.days)
      create(:payroll_run, :confirmation_report_uploaded,
        claims_counts: {Policies::StudentLoans => 2, Policies::EarlyCareerPayments => 2, Policies::TargetedRetentionIncentivePayments => 2, [Policies::StudentLoans, Policies::EarlyCareerPayments] => 2, [Policies::StudentLoans, Policies::TargetedRetentionIncentivePayments] => 2},
        created_at: 2.months.ago - 5.days)
      create(:payroll_run, :confirmation_report_uploaded,
        claims_counts: {Policies::StudentLoans => 2, Policies::EarlyCareerPayments => 2, Policies::TargetedRetentionIncentivePayments => 2, [Policies::StudentLoans, Policies::EarlyCareerPayments] => 2, [Policies::StudentLoans, Policies::TargetedRetentionIncentivePayments] => 2},
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

if Rails.env.development? || ENV["ENVIRONMENT_NAME"].start_with?("review")
  file = File.new(Rails.root.join("spec/fixtures/files/eligible_fe_providers.csv"))

  file_upload = FileUpload.create(
    uploaded_by: DfeSignIn::User.first,
    body: File.read(file),
    target_data_model: EligibleFeProvider.to_s,
    academic_year: AcademicYear.current.to_s
  )

  EligibleFeProvidersImporter.new(file, AcademicYear.current).run(file_upload.id)
  file_upload.completed_processing!
end

def eligibility_attrs
  {
    award_amount: [2500.0, 3000.0, 4000.0, 5000.0, 6000.0].sample,
    building_construction_courses: ["tlevel_building"],
    chemistry_courses: [],
    computing_courses: [],
    contract_type: "permanent",
    early_years_courses: [],
    engineering_manufacturing_courses: [],
    flagged_as_duplicate: false,
    further_education_teaching_start_year: "2020",
    half_teaching_hours: true,
    hours_teaching_eligible_subjects: true,
    maths_courses: [],
    physics_courses: [],
    provider_verification_email_count: 1,
    provider_verification_email_last_sent_at: Time.now + 5.minutes,
    provision_search: "SMB Group",
    # one from schools.yml and in eligible_fe_providers.csv
    school_id: School.find_by(ukprn: "10000952").id,
    subject_to_disciplinary_action: false,
    subject_to_formal_performance_action: false,
    subjects_taught: ["building_construction"],
    teacher_reference_number: "",
    teaching_hours_per_week: "more_than_12",
    teaching_qualification: "yes",
    teaching_responsibilities: true,
    verification: {}
  }
end

def national_insurance_number
  valid_letters = ("A".."Z").to_a - %w[D F I Q U V]
  prefix = 2.times.map { valid_letters.sample }.join
  digits = rand(10**6).to_s.rjust(6, "0")
  suffix = %w[A B C D].sample

  "#{prefix}#{digits}#{suffix}"
end

def claim_attrs
  dob = Faker::Date.birthday(min_age: 21, max_age: 50)
  first_name = Faker::Name.first_name
  last_name = Faker::Name.last_name
  full_name = "#{first_name} #{last_name}"
  email = Faker::Internet.email

  {
    academic_year: AcademicYear.current,
    address_line_1: rand(1..100).to_s,
    address_line_2: Faker::Address.street_name,
    address_line_3: Faker::Address.city,
    bank_account_number: Faker::Bank.account_number(digits: 8),
    bank_sort_code: Faker::Number.number(digits: 6).to_s,
    banking_name: full_name,
    date_of_birth: dob,
    dqt_teacher_status: {},
    eligibility_type: "Policies::FurtherEducationPayments::Eligibility",
    email_address: email,
    email_verified: true,
    first_name: first_name,
    govuk_verify_fields: [],
    held: false,
    hmrc_bank_validation_responses: [],
    hmrc_bank_validation_succeeded: false,
    identity_confirmed_with_onelogin: true,
    # NOTE: leaving out the journey_session, too much effort to seed
    journeys_session_id: nil,
    logged_in_with_onelogin: true,
    middle_name: "",
    national_insurance_number: national_insurance_number,
    onelogin_auth_at: Time.now,
    onelogin_idv_at: Time.now + 2.minutes,
    onelogin_idv_date_of_birth: dob,
    onelogin_idv_first_name: first_name,
    onelogin_idv_full_name: full_name,
    onelogin_idv_last_name: last_name,
    onelogin_idv_return_codes: [],
    onelogin_uid: SecureRandom.uuid,
    onelogin_user_info: {"email" => email},
    payroll_gender: ["male", "female"].sample,
    policy_options_provided: [],
    policy: Policies::FurtherEducationPayments,
    postcode: Faker::Address.postcode,
    provide_mobile_number: false,
    qa_required: false,
    reference: Reference.new.to_s,
    sent_one_time_password_at: Time.now,
    started_at: Time.now,
    submitted_at: Time.now,
    submitted_using_slc_data: false,
    surname: last_name,
    teacher_id_user_info: {}
  }
end

if Rails.env.development? || ENV["ENVIRONMENT_NAME"].start_with?("review")
  # Create some DfE signin users for provider verification
  provider_users = [
    {
      dfe_sign_in_id: "provider-1",
      given_name: "John",
      family_name: "Smith",
      email: "john.smith@example.com",
      role_codes: ["teacher_payments_claim_verifier"],
      current_organisation_ukprn: "10000952"
    },
    {
      dfe_sign_in_id: "provider-2",
      given_name: "Jane",
      family_name: "Doe",
      email: "jane.doe@example.com",
      role_codes: ["teacher_payments_claim_verifier"],
      current_organisation_ukprn: "10000952"
    }
  ]

  provider_users.each do |user_attrs|
    DfeSignIn::User.find_or_create_by!(dfe_sign_in_id: user_attrs[:dfe_sign_in_id]) do |user|
      user.attributes = user_attrs
    end
  end

  20.times do
    eligibility = Policies::FurtherEducationPayments::Eligibility.create!(eligibility_attrs)
    Claim.create! claim_attrs.merge(eligibility: eligibility)
  end
end

if ENV["ENVIRONMENT_NAME"].start_with?("review")
  SchoolDataImporterJob.perform_later if School.count < 100
end
