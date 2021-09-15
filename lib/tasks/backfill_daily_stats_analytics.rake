desc 'For backfilling analytics CSVs'
task backfill_daily_stats: :environment do
  (Date.new(2021,9,6)..Date.new(2021,9,14)).each do |date|
    SendAnalytics::DailyStatsJob.perform_later(date: date)
    SendAnalytics::DecisionsJob.perform_later(date: date)
  end
end
