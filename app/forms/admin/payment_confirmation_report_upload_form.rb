class Admin::PaymentConfirmationReportUploadForm
  include ActiveModel::Model
  include ActiveModel::Attributes

  attribute :file

  validates :file, presence: {message: "Choose a file to upload"}

  validate :validate_importer_errors

  attr_reader :admin_user, :payroll_run

  def initialize(params, payroll_run, admin_user)
    super(params)

    @admin_user = admin_user
    @payroll_run = payroll_run
  end

  def importer
    @importer ||= PaymentConfirmationUpload.new(payroll_run, file, admin_user)
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
