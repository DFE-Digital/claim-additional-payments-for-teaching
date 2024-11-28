class ImportStudentLoansDataJob < FileImporterJob
  import_with StudentLoansDataImporter do
    Rails.logger.info "SLC data imported; student loan verifiers will re-run where necessary"

    StudentLoanAmountCheckJob.perform_later
    StudentLoanPlanCheckJob.perform_later
  end
  rescue_with -> do
    StudentLoansData.delete_all
    AnalyticsImporter.import(StudentLoansData)
  end
  notify_with AdminMailer, success: :slc_csv_processing_success, failure: :slc_csv_processing_error
end
