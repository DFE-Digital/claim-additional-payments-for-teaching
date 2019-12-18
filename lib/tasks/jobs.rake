namespace :jobs do
  desc "Schedule all cron jobs"
  task schedule: :environment do
    CronJobScheduler.new.run
  end
end
