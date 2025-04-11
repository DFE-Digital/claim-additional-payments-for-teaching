class SolidQueueJobs < ActiveRecord::Migration[8.0]
  def up
    # delete all cron jobs
    Delayed::Job.where.not(cron: nil).destroy_all

    # migrate existing delayed jobs to solid queue
    Delayed::Job.all.each do |dj|
      klass = dj.payload_object.job_data["job_class"].constantize

      if klass == ActionMailer::MailDeliveryJob
        mailer_class = dj.payload_object.job_data["arguments"][0].constantize
        mailer_method = dj.payload_object.job_data["arguments"][1]
        mailer_args = ActiveJob::Arguments.deserialize(dj.payload_object.job_data["arguments"][3]["args"])[0]

        mailer_class.public_send(mailer_method, mailer_args).deliver_later
      else
        args = ActiveJob::Arguments.deserialize dj.payload_object.job_data["arguments"]

        klass.perform_later(*args)
      end
    end
  end

  def down
    SolidQueue::Job.destroy_all
  end
end
