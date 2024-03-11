# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rails db:seed command (or created alongside the database with db:setup).
#
# Examples:
#
#   movies = Movie.create([{ name: 'Star Wars' }, { name: 'Lord of the Rings' }])
#   Character.create(name: 'Luke', movie: movies.first)

if Rails.env.development? || ENV["ENVIRONMENT_NAME"] == "review"
  PolicyConfiguration.create!(policy_types: [StudentLoans], current_academic_year: AcademicYear.current)
  PolicyConfiguration.create!(policy_types: [EarlyCareerPayments, LevellingUpPremiumPayments], current_academic_year: AcademicYear.current)
  PolicyConfiguration.create!(policy_types: [Irp], current_academic_year: AcademicYear.current)

  ENV["FIXTURES_PATH"] = "spec/fixtures"
  ENV["FIXTURES"] = "local_authorities,local_authority_districts,schools"
  Rake::Task["db:fixtures:load"].invoke
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
        claims_counts: {StudentLoans => 2, EarlyCareerPayments => 2, LevellingUpPremiumPayments => 2, [StudentLoans, EarlyCareerPayments] => 2, [StudentLoans, LevellingUpPremiumPayments] => 2},
        created_at: 3.months.ago - 10.days)
      create(:payroll_run, :confirmation_report_uploaded,
        claims_counts: {StudentLoans => 2, EarlyCareerPayments => 2, LevellingUpPremiumPayments => 2, [StudentLoans, EarlyCareerPayments] => 2, [StudentLoans, LevellingUpPremiumPayments] => 2},
        created_at: 2.months.ago - 5.days)
      create(:payroll_run, :confirmation_report_uploaded,
        claims_counts: {StudentLoans => 2, EarlyCareerPayments => 2, LevellingUpPremiumPayments => 2, [StudentLoans, EarlyCareerPayments] => 2, [StudentLoans, LevellingUpPremiumPayments] => 2},
        created_at: 1.months.ago - 3.days)

      Policies.all.each do |policy|
        create_list(:claim, 23, :approved, policy: policy)
        create_list(:claim, 8, :submitted, policy: policy)
        create_list(:claim, 2, :submitted, :bank_details_not_validated, policy: policy)
        create_list(:claim, 5, :rejected, policy: policy)
        create_list(:claim, 1, :unverified, policy: policy)
      end

    # TODO: Remove this or configure for this and future years
    elsif ENV["SEED_ACADEMIC_YEAR"] == "2021"
      # This should probably be updated each year to:
      #  - reflect the reality of what is occuring in that years claim window
      #  - e.g. in 2021, M+P is not longer running
      #    There cannot be teachers claiming TSLR & ECP as the 2020/2021 Physics cohort is not eligible

      create(:payroll_run, :confirmation_report_uploaded,
        claims_counts: {StudentLoans => 10, EarlyCareerPayments => 15},
        created_at: 3.months.ago - 10.days)
      create(:payroll_run, :confirmation_report_uploaded,
        claims_counts: {StudentLoans => 8, EarlyCareerPayments => 25},
        created_at: 2.months.ago - 5.days)
      create(:payroll_run, :confirmation_report_uploaded,
        claims_counts: {StudentLoans => 2, EarlyCareerPayments => 10},
        created_at: 1.months.ago - 3.days)

      policy = StudentLoans
      create_list(:claim, 4, :approved, policy: policy)
      create_list(:claim, 1, :submitted, policy: policy)
      create_list(:claim, 1, :rejected, policy: policy)
      create_list(:claim, 1, :unverified, policy: policy)

      policy = EarlyCareerPayments
      create_list(:claim, 12, :approved, policy: policy)
      create_list(:claim, 1, :submitted, policy: policy)
      create_list(:claim, 1, :rejected, policy: policy)
      create_list(:claim, 1, :unverified, policy: policy)
    end
  end
end
