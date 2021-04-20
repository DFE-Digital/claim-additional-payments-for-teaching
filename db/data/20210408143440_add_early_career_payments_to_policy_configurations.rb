# Run me with `rails runner db/data/20210408143440_add_early_career_payments_to_policy_configurations.rb`

# Put your Ruby code here
PolicyConfiguration.create!(
  policy_type: EarlyCareerPayments,
  current_academic_year: AcademicYear.new("2021/2022")
)
