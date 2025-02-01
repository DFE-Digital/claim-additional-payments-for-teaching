class Admin::EligibleEyProvidersForm
  include ActiveModel::Model
  include ActiveModel::Attributes

  attribute :file

  validates :file,
    presence: {message: "Choose a CSV file of eligible EY providers to upload"}

  validate :validate_importer_errors

  attr_reader :uploaded_by

  def initialize(params, uploaded_by)
    super(params)

    @uploaded_by = uploaded_by
  end

  def importer
    @importer ||= EligibleEyProvidersImporter.new(file)
  end

  def file_upload
    @file_upload ||= FileUpload.new(uploaded_by:, body: File.read(file), target_data_model: EligibleEyProvider.to_s)
  end

  def run_import!
    file_upload.save!
    importer.run(file_upload.id)
    file_upload.completed_processing!
  end

  private

  # importer is not activemodel::errors compliant
  def validate_importer_errors
    importer.errors.each do |error|
      errors.add(:file, error)
    end
  end
end
