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
  Journeys::Configuration.find_or_create_by!(routing_name: Journeys::TeacherStudentLoanReimbursement::ROUTING_NAME) { |config| config.current_academic_year = AcademicYear.current }
  Journeys::Configuration.find_or_create_by!(routing_name: Journeys::TargetedRetentionIncentivePayments::ROUTING_NAME) { |config| config.current_academic_year = AcademicYear.current }
  Journeys::Configuration.find_or_create_by!(routing_name: Journeys::GetATeacherRelocationPayment::ROUTING_NAME) { |config| config.current_academic_year = AcademicYear.current }
  Journeys::Configuration.find_or_create_by!(routing_name: Journeys::FurtherEducationPayments::ROUTING_NAME) { |config| config.current_academic_year = AcademicYear.current }
  Journeys::Configuration.find_or_create_by!(routing_name: Journeys::EarlyYearsPayment::Provider::Start::ROUTING_NAME) { |config| config.current_academic_year = AcademicYear.current }
  Journeys::Configuration.find_or_create_by!(routing_name: Journeys::EarlyYearsPayment::Provider::Authenticated::ROUTING_NAME) { |config| config.current_academic_year = AcademicYear.current }
  Journeys::Configuration.find_or_create_by!(routing_name: Journeys::EarlyYearsPayment::Practitioner::ROUTING_NAME) { |config| config.current_academic_year = AcademicYear.current }
  Journeys::Configuration.find_or_create_by!(routing_name: Journeys::EarlyYearsPayment::Provider::AlternativeIdv::ROUTING_NAME) { |config| config.current_academic_year = AcademicYear.current }

  ENV["FIXTURES_PATH"] = "spec/fixtures"
  ENV["FIXTURES"] = "local_authorities,local_authority_districts,schools"
  begin
    Rake::Task["db:fixtures:load"].invoke
  rescue RuntimeError => e
    puts "Skipping fixtures load: #{e.message}" if Rails.env.development?
  end
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
    target_data_model: Policies::FurtherEducationPayments::EligibleFeProvider.to_s,
    academic_year: AcademicYear.current.to_s
  )

  Policies::FurtherEducationPayments::EligibleFeProvidersImporter.new(file, AcademicYear.current).run(file_upload.id)
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
  20.times do
    eligibility = Policies::FurtherEducationPayments::Eligibility.create!(eligibility_attrs)
    Claim.create! claim_attrs.merge(eligibility: eligibility)
  end
end

if ENV["ENVIRONMENT_NAME"].start_with?("review")
  SchoolDataImporterJob.perform_later if School.count < 100
end

# ==============================================================================
# QA TEST DATA - Year 2 Provider Verification Failure Scenarios
# TODO: DELETE THIS SECTION AFTER QA TESTING IS COMPLETE
# ==============================================================================
# This section creates 10 claims for the 2025/2026 academic year with provider
# verification completed. Each claim fails for a specific reason to test the
# Year 2 provider verification auto-check logic.
# ==============================================================================

if Rails.env.development? || ENV["ENVIRONMENT_NAME"].start_with?("review")
  # Create a provider user for verification
  provider_user = DfeSignIn::User.find_or_create_by!(
    dfe_sign_in_id: "qa-provider-verification-user",
    user_type: "provider",
    given_name: "QA",
    family_name: "Provider",
    email: "qa.provider@education.gov.uk",
    organisation_name: "SMB Group"
  )

  # Find eligible school
  eligible_school = School.find_by(ukprn: "10000952")

  # Base eligibility attributes for Year 2 claims
  def year2_base_eligibility(provider_user_id, school_id)
    {
      award_amount: 6000.0,
      building_construction_courses: [],
      chemistry_courses: [],
      computing_courses: [],
      early_years_courses: [],
      engineering_manufacturing_courses: [],
      flagged_as_duplicate: false,
      further_education_teaching_start_year: "2023",
      half_teaching_hours: true,
      hours_teaching_eligible_subjects: true,
      maths_courses: ["gcse_maths"],
      physics_courses: [],
      provision_search: "SMB Group",
      school_id: school_id,
      subject_to_disciplinary_action: false,
      subject_to_formal_performance_action: false,
      subjects_taught: ["maths"],
      teacher_reference_number: "1234567",
      teaching_hours_per_week: "more_than_12",
      teaching_qualification: "yes",
      teaching_responsibilities: true,
      contract_type: "permanent",
      # Year 2 provider verification fields
      provider_verification_teaching_responsibilities: true,
      provider_verification_teaching_start_year_matches_claim: true,
      provider_verification_teaching_qualification: "yes",
      provider_verification_contract_type: "permanent",
      provider_verification_teaching_hours_per_week: "20_or_more_hours_per_week",
      provider_verification_half_teaching_hours: true,
      provider_verification_performance_measures: false,
      provider_verification_disciplinary_action: false,
      provider_verification_completed_at: Time.zone.now,
      provider_verification_verified_by_id: provider_user_id,
      provider_verification_declaration: true
    }
  end

  def year2_base_claim(reference_suffix)
    dob = Date.new(1990, 5, 15)
    first_name = "QA"
    last_name = "Test#{reference_suffix}"
    full_name = "#{first_name} #{last_name}"
    email = "qa.test#{reference_suffix}@example.com"

    {
      academic_year: AcademicYear.new("2025/2026"),
      address_line_1: "123",
      address_line_2: "Test Street",
      address_line_3: "Test Town",
      bank_account_number: "12345678",
      bank_sort_code: "123456",
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
      journeys_session_id: nil,
      logged_in_with_onelogin: true,
      middle_name: "",
      national_insurance_number: "QQ12345#{reference_suffix}C",
      onelogin_auth_at: Time.zone.now,
      onelogin_idv_at: Time.zone.now + 2.minutes,
      onelogin_idv_date_of_birth: dob,
      onelogin_idv_first_name: first_name,
      onelogin_idv_full_name: full_name,
      onelogin_idv_last_name: last_name,
      onelogin_idv_return_codes: [],
      onelogin_uid: SecureRandom.uuid,
      onelogin_user_info: {"email" => email},
      payroll_gender: "male",
      policy_options_provided: [],
      policy: Policies::FurtherEducationPayments,
      postcode: "TE5 7ST",
      provide_mobile_number: false,
      qa_required: false,
      reference: "QAYR2#{reference_suffix.to_s.rjust(3, "0")}",
      sent_one_time_password_at: Time.zone.now,
      started_at: Time.zone.now,
      submitted_at: Time.zone.now,
      submitted_using_slc_data: false,
      surname: last_name,
      teacher_id_user_info: {}
    }
  end

  # Scenario 1: Teaching responsibilities - Provider says No
  puts "Creating QA claim 1: Teaching responsibilities failure..."
  eligibility_1 = Policies::FurtherEducationPayments::Eligibility.create!(
    year2_base_eligibility(provider_user.id, eligible_school.id).merge(
      provider_verification_teaching_responsibilities: false
    )
  )
  claim_1 = Claim.create!(year2_base_claim("001").merge(eligibility: eligibility_1))
  AutomatedChecks::ClaimVerifiers::ProviderVerificationV2.new(claim: claim_1).perform

  # Scenario 2: First 5 years - Provider says No
  puts "Creating QA claim 2: First 5 years failure..."
  eligibility_2 = Policies::FurtherEducationPayments::Eligibility.create!(
    year2_base_eligibility(provider_user.id, eligible_school.id).merge(
      provider_verification_teaching_start_year_matches_claim: false
    )
  )
  claim_2 = Claim.create!(year2_base_claim("002").merge(eligibility: eligibility_2))
  AutomatedChecks::ClaimVerifiers::ProviderVerificationV2.new(claim: claim_2).perform

  # Scenario 3: Teaching qualification - Provider says No (completely unqualified)
  puts "Creating QA claim 3: Teaching qualification failure..."
  eligibility_3 = Policies::FurtherEducationPayments::Eligibility.create!(
    year2_base_eligibility(provider_user.id, eligible_school.id).merge(
      provider_verification_teaching_qualification: "no"
    )
  )
  claim_3 = Claim.create!(year2_base_claim("003").merge(eligibility: eligibility_3))
  AutomatedChecks::ClaimVerifiers::ProviderVerificationV2.new(claim: claim_3).perform

  # Scenario 4: Performance measures - Provider says Yes
  puts "Creating QA claim 4: Performance measures failure..."
  eligibility_4 = Policies::FurtherEducationPayments::Eligibility.create!(
    year2_base_eligibility(provider_user.id, eligible_school.id).merge(
      provider_verification_performance_measures: true
    )
  )
  claim_4 = Claim.create!(year2_base_claim("004").merge(eligibility: eligibility_4))
  AutomatedChecks::ClaimVerifiers::ProviderVerificationV2.new(claim: claim_4).perform

  # Scenario 5: Disciplinary action - Provider says Yes
  puts "Creating QA claim 5: Disciplinary action failure..."
  eligibility_5 = Policies::FurtherEducationPayments::Eligibility.create!(
    year2_base_eligibility(provider_user.id, eligible_school.id).merge(
      provider_verification_disciplinary_action: true
    )
  )
  claim_5 = Claim.create!(year2_base_claim("005").merge(eligibility: eligibility_5))
  AutomatedChecks::ClaimVerifiers::ProviderVerificationV2.new(claim: claim_5).perform

  # Scenario 6: Contract type mismatch
  puts "Creating QA claim 6: Contract type mismatch..."
  eligibility_6 = Policies::FurtherEducationPayments::Eligibility.create!(
    year2_base_eligibility(provider_user.id, eligible_school.id).merge(
      contract_type: "permanent",
      provider_verification_contract_type: "fixed_term",
      provider_verification_contract_covers_full_academic_year: true
    )
  )
  claim_6 = Claim.create!(year2_base_claim("006").merge(eligibility: eligibility_6))
  AutomatedChecks::ClaimVerifiers::ProviderVerificationV2.new(claim: claim_6).perform

  # Scenario 7: Teaching hours mismatch
  puts "Creating QA claim 7: Teaching hours mismatch..."
  eligibility_7 = Policies::FurtherEducationPayments::Eligibility.create!(
    year2_base_eligibility(provider_user.id, eligible_school.id).merge(
      teaching_hours_per_week: "more_than_12",
      provider_verification_teaching_hours_per_week: "2_and_a_half_to_12_hours_per_week"
    )
  )
  claim_7 = Claim.create!(year2_base_claim("007").merge(eligibility: eligibility_7))
  AutomatedChecks::ClaimVerifiers::ProviderVerificationV2.new(claim: claim_7).perform

  # Scenario 8: Half teaching hours - Provider says No
  puts "Creating QA claim 8: Half teaching hours failure..."
  eligibility_8 = Policies::FurtherEducationPayments::Eligibility.create!(
    year2_base_eligibility(provider_user.id, eligible_school.id).merge(
      provider_verification_half_teaching_hours: false
    )
  )
  claim_8 = Claim.create!(year2_base_claim("008").merge(eligibility: eligibility_8))
  AutomatedChecks::ClaimVerifiers::ProviderVerificationV2.new(claim: claim_8).perform

  # Scenario 9: Variable hours - No term taught
  puts "Creating QA claim 9: Variable hours - no term taught..."
  eligibility_9 = Policies::FurtherEducationPayments::Eligibility.create!(
    year2_base_eligibility(provider_user.id, eligible_school.id).merge(
      contract_type: "variable_hours",
      provider_verification_contract_type: "variable_hours",
      provider_verification_taught_at_least_one_academic_term: false
    )
  )
  claim_9 = Claim.create!(year2_base_claim("009").merge(eligibility: eligibility_9))
  AutomatedChecks::ClaimVerifiers::ProviderVerificationV2.new(claim: claim_9).perform

  # Scenario 10: Fixed-term - Both full year and term as No
  puts "Creating QA claim 10: Fixed-term - both conditions fail..."
  eligibility_10 = Policies::FurtherEducationPayments::Eligibility.create!(
    year2_base_eligibility(provider_user.id, eligible_school.id).merge(
      contract_type: "fixed_term",
      provider_verification_contract_type: "fixed_term",
      provider_verification_contract_covers_full_academic_year: false,
      provider_verification_taught_at_least_one_academic_term: false
    )
  )
  claim_10 = Claim.create!(year2_base_claim("010").merge(eligibility: eligibility_10))
  AutomatedChecks::ClaimVerifiers::ProviderVerificationV2.new(claim: claim_10).perform

  # Bonus: Scenario 11 - PASSING claim for comparison
  puts "Creating QA claim 11: PASSING claim (all conditions met)..."
  eligibility_11 = Policies::FurtherEducationPayments::Eligibility.create!(
    year2_base_eligibility(provider_user.id, eligible_school.id)
    # All base values are already set to pass
  )
  claim_11 = Claim.create!(year2_base_claim("011").merge(eligibility: eligibility_11))
  AutomatedChecks::ClaimVerifiers::ProviderVerificationV2.new(claim: claim_11).perform

  puts "✅ Created 11 QA test claims for Year 2 provider verification (10 failures + 1 pass)"
end

# ==============================================================================
# END QA TEST DATA
# ==============================================================================
