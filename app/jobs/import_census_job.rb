class ImportCensusJob < ApplicationJob
  def perform(file_upload_id)
    # NOTE: the `body` column is a large blob, use pluck to stream it straight into a file and not in memory
    Tempfile.new.tap do |file|
      file.write(FileUpload.where(id: file_upload_id).pluck(:body).first)
      file.rewind
      SchoolWorkforceCensusDataImporter.new(file).run
      file.close!
    end

    # Success email notification
    user = load_user(file_upload_id)
    AdminMailer.census_csv_processing_success(user.email).deliver_now if user&.email

    # Delete the file upload
    FileUpload.delete(file_upload_id)
  rescue => e
    Rollbar.error(e)
    SchoolWorkforceCensus.delete_all
    user = load_user(file_upload_id)
    AdminMailer.census_csv_processing_error(user.email).deliver_now if user&.email
  end

  private

  def load_user(file_upload_id)
    # Avoid loading the `body` blob into memory
    uploaded_by_id = FileUpload.where(id: file_upload_id).pluck(:uploaded_by_id).first

    DfeSignIn::User.find_by_id(uploaded_by_id)
  end
end
