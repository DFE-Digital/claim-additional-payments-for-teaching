class SendDecisionsAnalyticsJob < CronJob
  self.cron_expression = "0 3 * * *" # every day at 3am

  queue_as :analytics

  def perform
    Rails.logger.info "Sending decisions analytics CSV..."
    SendAnalyticsCsv.new(
      query: query,
      file_name: file_name
    ).call
  end

  private

  def query
    @query ||= ClaimDecision.yesterday
  end

  def file_name
    @file_name ||= "decisions-analytics_#{date}.csv"
  end

  def date
    @date ||= Date.today.strftime("%Y%m%d")
  end
end
