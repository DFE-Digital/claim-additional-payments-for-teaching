class Admin::DqtHigherEducationQualificationUploadForm
  include ActiveModel::Model
  include ActiveModel::Attributes

  attribute :file

  validates :file,
    presence: {message: "Choose a CSV file with Higher Education Qualifications data to upload"}

  validate :validate_importer_errors

  attr_reader :admin_user

  def initialize(params, admin_user)
    super(params)

    @admin_user = admin_user
  end

  def importer
    @importer ||= DqtHigherEducationQualificationDataImporter.new(file)
  end

  def file_upload
    @file_upload ||= FileUpload.new(
      uploaded_by: admin_user,
      body: File.read(file),
      target_data_model: DqtHigherEducationQualification.to_s
    )
  end

  def run_import!
    file_upload.save!
    ImportDqtHigherEducationQualificationsJob.perform_later(file_upload.id)
  end

  private

  # importer is not activemodel::errors compliant
  def validate_importer_errors
    importer.errors.each do |error|
      errors.add(:file, error)
    end
  end
end
