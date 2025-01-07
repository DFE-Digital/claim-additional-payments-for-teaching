class DeleteFileUploadsAndDownloadsJob < ApplicationJob
  def perform
    FileUpload.delete_files(
      target_data_model: PaymentConfirmation,
      older_than: AcademicYear.next.start_of_autumn_term.to_datetime
    )

    FileDownload.delete_files(
      source_data_model: PayrollRun,
      older_than: AcademicYear.next.start_of_autumn_term.to_datetime
    )
  end
end
