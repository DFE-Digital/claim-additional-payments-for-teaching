class Admin::EligibleEyProvidersForm
  include ActiveModel::Model
  include ActiveModel::Attributes

  attribute :file

  validates :file,
    presence: {message: "Choose a CSV file of eligible EY providers to upload"}

  validate :validate_importer_errors

  def importer
    @importer ||= EligibleEyProvidersImporter.new(file)
  end

  private

  # importer is not activemodel::errors compliant
  def validate_importer_errors
    importer.errors.each do |error|
      errors.add(:file, error)
    end
  end
end
