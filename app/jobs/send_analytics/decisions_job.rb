module SendAnalytics
  class DecisionsJob < CronJob
    self.cron_expression = "0 3 * * *" # every day at 3am

    queue_as :analytics

    def perform(date: Date.yesterday)
      Rails.logger.info "Sending decisions stats CSV for #{date}..."
      ::SendAnalytics::Decisions.new(date: date).call
    end
  end
end
