class Admin::QualificationReportForm
  include ActiveModel::Model
  include ActiveModel::Attributes

  attribute :file

  validates :file,
    presence: {message: "Choose a qualification report file to upload"}

  validate :validate_importer_errors

  attr_reader :admin_user

  def initialize(params, admin_user)
    super(params)

    @admin_user = admin_user
  end

  def importer
    @importer ||= AutomatedChecks::DqtReportConsumer.new(file, admin_user)
  end

  def run_import!
    importer.ingest
  end

  private

  # importer is not activemodel::errors compliant
  def validate_importer_errors
    importer.errors.each do |error|
      errors.add(:file, error)
    end
  end
end
