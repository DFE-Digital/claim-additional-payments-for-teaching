class PurgeOldJobsJob < ApplicationJob
  def perform
    SolidQueue::Job.clear_finished_in_batches
  end
end
