# Run me with `rails runner db/data/20250512170043_backfill_student_loans_eligibilities_qts_award_year_string.rb`

# NOTE: It's OK to do `update_all` as the `qts_award_year_string` field is in the `analytics_blocklist.yml`

QTS_AWARD_YEARS = %w[
  before_cut_off_date
  on_or_after_cut_off_date
]

# BEFORE
QTS_AWARD_YEARS.each do |qts_award_year|
  count = Policies::StudentLoans::Eligibility
    .where(qts_award_year: qts_award_year)
    .count

  puts "#{qts_award_year} - count: #{count}"
end

# MIGRATE
QTS_AWARD_YEARS.each do |qts_award_year|
  Policies::StudentLoans::Eligibility
    .where(qts_award_year: qts_award_year)
    .update_all(qts_award_year_string: qts_award_year)
end

# AFTER
QTS_AWARD_YEARS.each do |qts_award_year|
  count = Policies::StudentLoans::Eligibility
    .where(qts_award_year_string: qts_award_year)
    .count

  puts "#{qts_award_year}_string - count: #{count}"
end
