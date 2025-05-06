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

if Rails.env.development? || ENV["ENVIRONMENT_NAME"].start_with?("review")
  require "./lib/factory_helpers"

  class Seeds
    extend FactoryBot::Syntax::Methods

    FactoryHelpers.create_factory_registry
    FactoryHelpers.reset_factory_registry

    if ENV["SEED_ACADEMIC_YEAR"].nil? || ENV["ENVIRONMENT_NAME"].start_with?("review")
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

if ENV["ENVIRONMENT_NAME"].start_with?("review")
  file = File.new(Rails.root.join("spec/fixtures/files/eligible_fe_providers.csv"))

  file_upload = FileUpload.create(
    uploaded_by: DfeSignIn::User.first,
    body: File.read(file),
    target_data_model: EligibleFeProvider.to_s,
    academic_year: AcademicYear.current.to_s
  )

  EligibleFeProvidersImporter.new(file, AcademicYear.current).run(file_upload.id)
  file_upload.completed_processing!

  SchoolDataImporterJob.perform_later if School.count < 100
end
