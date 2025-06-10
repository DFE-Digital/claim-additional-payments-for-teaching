# Run me with `rails runner db/data/20250516122738_migrate_additional_payments_reminders_to_tslr.rb`

# Put your Ruby code here
tri_claimant_emails = Claim
  .by_policy(Policies::TargetedRetentionIncentivePayments)
  .by_academic_year(AcademicYear.new(2024))
  .joins("join targeted_retention_incentive_payments_eligibilities tri on tri.id = claims.eligibility_id")
  .where("tri.itt_academic_year != '2019/2020'")
  .select(:email_address)

reminders_to_migrate = Reminder
  .email_verified
  .not_yet_sent
  .where(itt_academic_year: AcademicYear.new(2025).to_s)
  .where(journey_class: "Journeys::AdditionalPaymentsForTeaching")
  .where(email_address: tri_claimant_emails)

reminders_to_migrate.update_all(journey_class: "Journeys::TargetedRetentionIncentivePayments")
