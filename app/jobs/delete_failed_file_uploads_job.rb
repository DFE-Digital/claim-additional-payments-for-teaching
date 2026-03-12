class DeleteFailedFileUploadsJob < ApplicationJob
  AGE_THRESHOLD = 3.months.freeze

  def perform
    FileUpload
      .where(completed_processing_at: nil)
      .where(created_at: ..AGE_THRESHOLD.ago)
      .destroy_all
  end
end
