class ImportStudentLoansDataJob < FileImporterJob
  import_with StudentLoansDataImporter do
    Rails.logger.info "SLC data imported; student loan verifiers will re-run where necessary"

    StudentLoanAmountCheckJob.perform_later
    StudentLoanPlanCheckJob.perform_later
  end
  rescue_with -> { StudentLoansData.delete_all }
end
