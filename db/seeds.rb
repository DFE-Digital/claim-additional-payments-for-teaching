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

    create(:payroll_run, :confirmation_report_uploaded, claims_counts: {StudentLoans => 22, MathsAndPhysics => 10}, created_at: 3.months.ago - 10.days)
    create(:payroll_run, :confirmation_report_uploaded, claims_counts: {StudentLoans => 12, MathsAndPhysics => 7}, created_at: 2.months.ago - 5.days)
    create(:payroll_run, claims_counts: {StudentLoans => 18, MathsAndPhysics => 8}, created_at: 1.months.ago - 3.days)

    Policies.all.each do |policy|
      create_list(:claim, 23, :approved, policy: policy)
      create_list(:claim, 10, :submitted, policy: policy)
      create_list(:claim, 5, :rejected, policy: policy)
      create_list(:claim, 1, :unverified, policy: policy)
    end
  end
end
