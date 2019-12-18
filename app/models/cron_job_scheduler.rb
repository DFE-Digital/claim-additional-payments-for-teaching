class CronJobScheduler
  def initialize
    Dir.glob(glob).each { |f| require f }
  end

  def schedule
    CronJob.subclasses.each { |job| job.schedule }
  end

  private

  def glob
    Rails.root.join("app", "jobs", "**", "*_job.rb")
  end
end
