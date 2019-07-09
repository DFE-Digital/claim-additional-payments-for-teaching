class CronJob < ApplicationJob
  class_attribute :cron_expression

  class << self
    def schedule
      remove_schedule if delayed_job.present? && delayed_job.cron != cron_expression

      set(cron: cron_expression).perform_later unless scheduled?
    end

    private

    def remove_schedule
      delayed_job.destroy if scheduled?
    end

    def remove
      delayed_job.destroy if scheduled?
    end

    def scheduled?
      delayed_job.present?
    end

    def delayed_job
      jobs.first
    end

    def jobs
      Delayed::Job
        .where("handler LIKE ?", "%job_class: #{name}%")
    end
  end
end
