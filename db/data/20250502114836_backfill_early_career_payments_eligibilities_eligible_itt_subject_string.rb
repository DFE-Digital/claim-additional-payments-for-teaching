# Run me with `rails runner db/data/20250502114836_backfill_early_career_payments_eligibilities_eligible_itt_subject_string.rb`

# NOTE: It's OK to do `update_all` as the `eligible_itt_subject_string` field is in the `analytics_blocklist.yml`

ELIGIBLE_ITT_SUBJECTS = %w[
  chemistry
  foreign_languages
  mathematics
  physics
  none_of_the_above
  computing
]

# BEFORE
ELIGIBLE_ITT_SUBJECTS.each do |eligible_itt_subject|
  count = Policies::EarlyCareerPayments::Eligibility
    .where(eligible_itt_subject: eligible_itt_subject)
    .count

  puts "#{eligible_itt_subject} - count: #{count}"
end

# MIGRATE
ELIGIBLE_ITT_SUBJECTS.each do |eligible_itt_subject|
  Policies::EarlyCareerPayments::Eligibility
    .where(eligible_itt_subject: eligible_itt_subject)
    .update_all(eligible_itt_subject_string: eligible_itt_subject)
end

# AFTER
ELIGIBLE_ITT_SUBJECTS.each do |eligible_itt_subject|
  count = Policies::EarlyCareerPayments::Eligibility
    .where(eligible_itt_subject_string: eligible_itt_subject)
    .count

  puts "#{eligible_itt_subject}_string - count: #{count}"
end
