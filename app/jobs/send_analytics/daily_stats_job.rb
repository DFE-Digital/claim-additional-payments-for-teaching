module SendAnalytics
  class DailyStatsJob < CronJob
    self.cron_expression = "0 3 * * *" # every day at 3am
  
    queue_as :analytics
  
    def perform(date: Date.yesterday)
      Rails.logger.info "Sending daily stats CSV for #{date}..."
      ClaimStats.refresh
      ::SendAnalytics::DailyStats.new(date: date).call
    end
  end  
end