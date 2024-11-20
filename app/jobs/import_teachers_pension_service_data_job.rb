class ImportTeachersPensionServiceDataJob < FileImporterJob
  import_with TeachersPensionsServiceImporter do
    Rails.logger.info "TPS data imported; queue employment check job"

    EmploymentCheckJob.perform_later
  end
  notify_with AdminMailer, success: :tps_csv_processing_success, failure: :tps_csv_processing_error
end
