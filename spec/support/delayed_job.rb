class DelayedJobTestAdapter < ActiveJob::QueueAdapters::DelayedJobAdapter
  def enqueued_jobs
    Delayed::Job.all.to_a
  end

  def performed_jobs
    []
  end
end

class TestCronJob < CronJob
  self.cron_expression = "* * * * *"

  def perform
  end
end

class TestWithPerformOnScheduleCronJob < CronJob
  self.cron_expression = "* * * * *"

  def perform
  end
end
