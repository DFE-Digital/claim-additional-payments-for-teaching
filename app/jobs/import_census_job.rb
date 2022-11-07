class ImportCensusJob < ApplicationJob
  def perform(file_upload)
    SchoolWorkforceCensusDataImporter.new(csv_string: file_upload.body).run
    AdminMailer.census_csv_processing_success(file_upload.uploaded_by.email).deliver_now if file_upload.uploaded_by&.email
    file_upload.delete
  rescue ActiveRecord::RecordInvalid => e
    Rollbar.error(e)
    AdminMailer.census_csv_processing_error(file_upload.uploaded_by.email).deliver_now if file_upload.uploaded_by&.email
  end
end
