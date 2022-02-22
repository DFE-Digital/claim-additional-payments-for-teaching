# This was built for the ECP processing
# valid dates are as follows:
# start_date - relates to policy, but for ECP in the 2021/2022 claim academic year was 6th of September
# end_date - maximum end date is yesterday
# Date uses the format 'YYYY-MM-DD' when running the task
desc "For backfilling all analytics CSVs"
task :backfill_all_stats, [:start_date, :end_date] => :environment do |t, args|
  args.with_defaults(start_date: "2021-09-06", end_date: Date.yesterday.to_s)
  logger = Logger.new($stdout)
  logger.info "Backfilling decision and daily stats for dates between #{args.start_date} and #{args.end_date}"

  start_date = Date.parse(args.start_date, "%Y-%m-%d")
  end_date = Date.parse(args.end_date, "%Y-%m-%d")

  (start_date..end_date).each do |date|
    SendAnalytics::DailyStatsJob.perform_later(date: date)
    SendAnalytics::DecisionsJob.perform_later(date: date)
  end
end

desc "For backfilling daily stats analytics CSVs"
task :backfill_daily_stats, [:start_date, :end_date] => :environment do |t, args|
  args.with_defaults(start_date: "2021-09-06", end_date: Date.yesterday.to_s)
  logger = Logger.new($stdout)
  logger.info "Backfilling daily stats for dates between #{args.start_date} and #{args.end_date}"

  start_date = Date.parse(args.start_date, "%Y-%m-%d")
  end_date = Date.parse(args.end_date, "%Y-%m-%d")

  (start_date..end_date).each do |date|
    SendAnalytics::DailyStatsJob.perform_later(date: date)
  end
end

desc "For backfilling decision stats analytics CSVs"
task :backfill_decision_stats, [:start_date, :end_date] => :environment do |t, args|
  args.with_defaults(start_date: "2021-09-06", end_date: Date.yesterday.to_s)
  logger = Logger.new($stdout)
  logger.info "Backfilling decision stats for dates between #{args.start_date} and #{args.end_date}"

  start_date = Date.parse(args.start_date, "%Y-%m-%d")
  end_date = Date.parse(args.end_date, "%Y-%m-%d")

  (start_date..end_date).each do |date|
    SendAnalytics::DecisionsJob.perform_later(date: date)
  end
end
