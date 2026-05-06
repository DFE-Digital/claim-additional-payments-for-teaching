class Admin::EligibleEytfiProvidersForm
  include ActiveModel::Model
  include ActiveModel::Attributes

  attribute :academic_year, AcademicYear::Type.new
  attribute :file

  validates :file,
    presence: {message: "Choose a CSV file of eligible EYTFI providers to upload"}

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

  def file_upload
    @file_upload ||= FileUpload.new(
      uploaded_by: admin_user,
      body: File.read(file),
      target_data_model: Policies::EarlyYearsTeachersFinancialIncentivePayments::EligibleEytfiProvider.to_s,
      academic_year: academic_year.to_s
    )
  end

  def save
    ApplicationRecord.transaction do
      file_upload.save!
      EarlyYearsTeachersFinancialIncentivePayments::ImportEligibleEytfiProvidersJob.perform_later(file_upload)
    end
  end
end
