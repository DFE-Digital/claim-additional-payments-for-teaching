class DeleteFileUploadsAndDownloadsJob < CronJob
  # At 10:00 PM, on day 31 of the month, only in August
  self.cron_expression = "0 22 31 8 *"

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
