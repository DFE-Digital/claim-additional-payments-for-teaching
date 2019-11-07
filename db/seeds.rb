# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rails db:seed command (or created alongside the database with db:setup).
#
# Examples:
#
#   movies = Movie.create([{ name: 'Star Wars' }, { name: 'Lord of the Rings' }])
#   Character.create(name: 'Luke', movie: movies.first)

PolicyConfiguration.create!(policy_type: StudentLoans)
PolicyConfiguration.create!(policy_type: MathsAndPhysics)

if Rails.env.development?
  ENV["FIXTURES_PATH"] = "spec/fixtures"
  Rake::Task["db:fixtures:load"].invoke

  class Seeds
    extend FactoryBot::Syntax::Methods

    create(:payroll_run, :confirmation_report_uploaded, claims_count: 32, created_at: 3.months.ago - 10.days)
    create(:payroll_run, :confirmation_report_uploaded, claims_count: 19, created_at: 2.months.ago - 5.days)
    create(:payroll_run, claims_count: 26, created_at: 1.months.ago - 3.days)

    create_list(:claim, 23, :approved)
    create_list(:claim, 10, :submitted)
    create_list(:claim, 5, :rejected)
  end
end
