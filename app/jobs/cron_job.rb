class CronJob < ApplicationJob
  class_attribute :cron_expression
  class_attribute :perform_on_schedule

  class << self
    def schedule
      remove_schedule if scheduled_job.present? && scheduled_job.cron != cron_expression

      set(cron: cron_expression).perform_later unless scheduled?
      perform_later if perform_on_schedule && !enqueued?
    end

    private

    def remove_schedule
      scheduled_job.destroy if scheduled?
    end

    def scheduled?
      scheduled_job.present?
    end

    def enqueued?
      enqueued_job.present?
    end

    def scheduled_job
      jobs.where.not(cron: nil).first
    end

    def enqueued_job
      jobs.where(cron: nil).first
    end

    def jobs
      Delayed::Job.where("handler LIKE ?", "%job_class: #{name}%")
    end
  end
end
