# Run me with `rails runner db/data/20250512170458_backfill_student_loans_eligibilities_employment_status_string.rb`

# NOTE: It's OK to do `update_all` as the `employment_status_string` field is in the `analytics_blocklist.yml`

EMPLOYMENT_STATUSES = %w[
  claim_school
  different_school
  no_school
  recent_tps_school
]

# BEFORE
EMPLOYMENT_STATUSES.each do |employment_status|
  count = Policies::StudentLoans::Eligibility
    .where(employment_status: employment_status)
    .count

  puts "#{employment_status} - count: #{count}"
end

# MIGRATE
EMPLOYMENT_STATUSES.each do |employment_status|
  Policies::StudentLoans::Eligibility
    .where(employment_status: employment_status)
    .update_all(employment_status_string: employment_status)
end

# AFTER
EMPLOYMENT_STATUSES.each do |employment_status|
  count = Policies::StudentLoans::Eligibility
    .where(employment_status_string: employment_status)
    .count

  puts "#{employment_status}_string - count: #{count}"
end
