class Admin::EligibleFeProvidersForm
  include ActiveModel::Model
  include ActiveModel::Attributes

  attribute :academic_year, AcademicYear::Type.new
  attribute :file

  validates :file,
    presence: {message: "Choose a CSV file of eligible FE providers to upload"}

  def select_options
    (0..2).map do |relative_year|
      academic_year = AcademicYear.current + relative_year
      OpenStruct.new(id: academic_year.start_year, name: academic_year)
    end
  end
end
