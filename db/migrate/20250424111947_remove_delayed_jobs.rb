class RemoveDelayedJobs < ActiveRecord::Migration[8.0]
  def change
    drop_table :delayed_jobs
  end
end
