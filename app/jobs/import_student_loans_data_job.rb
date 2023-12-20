class ImportStudentLoansDataJob < FileImporterJob
  import_with StudentLoansDataImporter do
    Rails.logger.info "SLC data imported; student loan amount task will re-run where necessary"
    StudentLoanAmountCheckJob.perform_later
  end
  rescue_with -> { StudentLoansData.delete_all }
end
