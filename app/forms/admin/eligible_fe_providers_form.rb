class Admin::EligibleFeProvidersForm
  include ActiveModel::Model
  include ActiveModel::Attributes

  attribute :academic_year, AcademicYear::Type.new
  attribute :file

  validates :file,
    presence: {message: "Choose a CSV file of eligible FE providers to upload"}

  validate :validate_importer_errors

  attr_reader :admin_user

  def initialize(params, admin_user)
    super(params)

    @admin_user = admin_user
  end

  def select_options
    (0..2).map do |relative_year|
      academic_year = AcademicYear.current + relative_year
      OpenStruct.new(id: academic_year.to_s, name: academic_year)
    end
  end

  def importer
    @importer ||= Policies::FurtherEducationPayments::EligibleFeProvidersImporter.new(
      file,
      academic_year
    )
  end

  def file_upload
    @file_upload ||= FileUpload.new(
      uploaded_by: admin_user,
      body: File.read(file),
      target_data_model: Policies::FurtherEducationPayments::EligibleFeProvider.to_s,
      academic_year: academic_year.to_s
    )
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
