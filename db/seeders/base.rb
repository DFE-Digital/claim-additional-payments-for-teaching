require "factory_bot"

module Seeders
  class Base
    def call
      load_factory_bot_definitions

      puts "Seeding journey configs..."
      create_journey_configurations

      puts "Seeding feature flags..."
      toggle_feature_flags

      puts "Seeding fixtures..."
      seed_fixures

      puts "Seeding payroll runs..."
      seed_payroll_runs

      puts "Seeding claims..."
      seed_claims

      puts "Seeding eligible FE providers..."
      seed_eligible_fe_providers

      puts "Importing schools from GIAS..."
      SchoolDataImporterJob.perform_now if School.count < 500
    end

    private

    def load_factory_bot_definitions
      FactoryBot.find_definitions
    rescue FactoryBot::DuplicateDefinitionError
      nil
    end

    def create_journey_configurations
      Journeys::Configuration.create!(routing_name: Journeys::TeacherStudentLoanReimbursement.routing_name, current_academic_year: AcademicYear.current)
      Journeys::Configuration.create!(routing_name: Journeys::TargetedRetentionIncentivePayments.routing_name, current_academic_year: AcademicYear.current)
      Journeys::Configuration.create!(routing_name: Journeys::GetATeacherRelocationPayment.routing_name, current_academic_year: AcademicYear.current)
      Journeys::Configuration.create!(routing_name: Journeys::FurtherEducationPayments.routing_name, current_academic_year: AcademicYear.current)
      Journeys::Configuration.create!(routing_name: Journeys::EarlyYearsPayment::Provider::Start.routing_name, current_academic_year: AcademicYear.current)
      Journeys::Configuration.create!(routing_name: Journeys::EarlyYearsPayment::Provider::Authenticated.routing_name, current_academic_year: AcademicYear.current)
      Journeys::Configuration.create!(routing_name: Journeys::EarlyYearsPayment::Practitioner.routing_name, current_academic_year: AcademicYear.current)
      Journeys::Configuration.create!(routing_name: Journeys::EarlyYearsPayment::Provider::AlternativeIdv.routing_name, current_academic_year: AcademicYear.current)
      Journeys::Configuration.create!(routing_name: Journeys::EarlyYearsTeachersFinancialIncentivePayments.routing_name, current_academic_year: AcademicYear.current)
    end

    def toggle_feature_flags
      FeatureFlag.enable!("fe_provider_dashboard")
      FeatureFlag.enable!("eytfi_journey")
    end

    def seed_fixures
      ENV["FIXTURES_PATH"] = "spec/fixtures"
      ENV["FIXTURES"] = "local_authorities,local_authority_districts,schools"
      Rake::Task["db:fixtures:load"].invoke
    end

    def seed_payroll_runs
      FactoryBot.create(
        :payroll_run,
        :confirmation_report_uploaded,
        claims_counts: {
          Policies::StudentLoans => 2,
          Policies::EarlyCareerPayments => 2,
          Policies::TargetedRetentionIncentivePayments => 2,
          [Policies::StudentLoans, Policies::EarlyCareerPayments] => 2,
          [Policies::StudentLoans, Policies::TargetedRetentionIncentivePayments] => 2
        },
        created_at: 3.months.ago
      )

      FactoryBot.create(
        :payroll_run,
        :confirmation_report_uploaded,
        claims_counts: {
          Policies::StudentLoans => 2,
          Policies::EarlyCareerPayments => 2,
          Policies::TargetedRetentionIncentivePayments => 2,
          [Policies::StudentLoans, Policies::EarlyCareerPayments] => 2,
          [Policies::StudentLoans, Policies::TargetedRetentionIncentivePayments] => 2
        },
        created_at: 2.months.ago
      )

      FactoryBot.create(
        :payroll_run,
        :confirmation_report_uploaded,
        claims_counts: {
          Policies::StudentLoans => 2,
          Policies::EarlyCareerPayments => 2,
          Policies::TargetedRetentionIncentivePayments => 2,
          [Policies::StudentLoans, Policies::EarlyCareerPayments] => 2,
          [Policies::StudentLoans, Policies::TargetedRetentionIncentivePayments] => 2
        },
        created_at: 1.months.ago
      )
    end

    def seed_claims
      Policies.all.each do |policy|
        FactoryBot.create_list(:claim, rand(10..20), :approved, policy: policy)
        FactoryBot.create_list(:claim, rand(5..10), :submitted, policy: policy)
        FactoryBot.create_list(:claim, rand(5..10), :submitted, :bank_details_not_validated, policy: policy)
        FactoryBot.create_list(:claim, rand(5..10), :rejected, policy: policy)
      end
    end

    def seed_eligible_fe_providers
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
  end
end
