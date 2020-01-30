# Writes "Heartbeat job performed" to the logs every minute. This message is
# evidence that the worker is working properly. We can use a log alerting tool
# to alert us if too much time passes without seeing one of these messages.
class HeartbeatJob < CronJob
  self.cron_expression = "* * * * *"

  queue_as :heartbeat

  def perform
    logger.info "Heartbeat job performed"
  end
end
