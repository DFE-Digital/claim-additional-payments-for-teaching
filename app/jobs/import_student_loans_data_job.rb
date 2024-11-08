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
end
