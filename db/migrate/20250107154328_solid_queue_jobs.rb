class SolidQueueJobs < ActiveRecord::Migration[8.0]
  def up
    # delete all cron jobs
    Delayed::Job.where.not(cron: nil).destroy_all

    # migrate existing delayed jobs to solid queue
    Delayed::Job.all.each do |dj|
      klass = dj.payload_object.job_data["job_class"].constantize
      args = dj.payload_object.job_data["arguments"].map do |hash|
        hash.values.map { |v| GlobalID::Locator.locate(v) }
      end.flatten

      klass.perform_later(args)
    end
  end

  def down
    SolidQueue::Job.destroy_all
  end
end
