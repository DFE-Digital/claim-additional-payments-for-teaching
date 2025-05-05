# Run me with `rails runner db/data/20250501180600_backfill_targeted_retention_incentive_payments_eligibilities_qualification_string.rb`

# NOTE: It's OK to do `update_all` as the `qualification_string` field is in the `analytics_blocklist.yml`

QUALIFICATIONS = %w[
  postgraduate_itt
  undergraduate_itt
  assessment_only
  overseas_recognition
]

# BEFORE
QUALIFICATIONS.each do |qualification|
  count = Policies::TargetedRetentionIncentivePayments::Eligibility
    .where(qualification: qualification)
    .count

  puts "#{qualification} - count: #{count}"
end

# MIGRATE
QUALIFICATIONS.each do |qualification|
  Policies::TargetedRetentionIncentivePayments::Eligibility
    .where(qualification: qualification)
    .update_all(qualification_string: qualification)
end

# AFTER
QUALIFICATIONS.each do |qualification|
  count = Policies::TargetedRetentionIncentivePayments::Eligibility
    .where(qualification_string: qualification)
    .count

  puts "#{qualification}_string - count: #{count}"
end
