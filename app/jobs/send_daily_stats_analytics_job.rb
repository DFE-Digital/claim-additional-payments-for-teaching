class SendDailyStatsAnalyticsJob < CronJob
  self.cron_expression = "0 3 * * *" # every day at 3am

  queue_as :analytics

  def perform
    Rails.logger.info "Sending Daily Stats CSV..."
    # refresh the materialized view backing this
    ClaimStats.refresh
    SendAnalyticsCsv.new(
      query: query,
      file_name: file_name
    ).call
  end

  private

  def query
    @query ||= ClaimStats::Daily
  end

  def file_name
    @file_name ||= "daily-stats/daily-stats-analytics_#{date}.csv"
  end

  def date
    @date ||= Date.yesterday.strftime("%Y%m%d")
  end
end
