class DfE::Analytics::EntityTableCheckJob < CronJob
  self.cron_expression = "30 0 * * *" # Every day at 00:30

  def perform
    DfE::Analytics::EntityTableCheckJob.new.perform
  end
end
