class Admin::EligibleFeProvidersForm
  include ActiveModel::Model
  include ActiveModel::Attributes

  attribute :academic_year, AcademicYear::Type.new
  attribute :file

  validates :file,
    presence: {message: "Choose a CSV file of eligible FE providers to upload"}

  validate :validate_importer_errors

  def select_options
    (0..2).map do |relative_year|
      academic_year = AcademicYear.current + relative_year
      OpenStruct.new(id: academic_year.to_s, name: academic_year)
    end
  end

  def importer
    @importer ||= EligibleFeProvidersImporter.new(
      file,
      academic_year
    )
  end

  private

  # importer is not activemodel::errors compliant
  def validate_importer_errors
    importer.errors.each do |error|
      errors.add(:file, error)
    end
  end
end
