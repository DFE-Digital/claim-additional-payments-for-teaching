class Admin::JourneyConfigurationForm
  include ActiveModel::Model
  include ActiveModel::Attributes

  attribute :journey_configuration
  attribute :current_academic_year, AcademicYear::Type.new
  attribute :open_for_submissions, :boolean
  attribute :availability_message, :string
  attribute :teacher_id_enabled, :boolean

  def self.for_journey_configuration(journey_configuration)
    new(
      journey_configuration:,
      current_academic_year: journey_configuration.current_academic_year,
      open_for_submissions: journey_configuration.open_for_submissions,
      availability_message: journey_configuration.availability_message,
      teacher_id_enabled: journey_configuration.teacher_id_enabled
    )
  end

  def academic_year_select_options
    (0..3).map do |relative_year|
      Form::Option.new(
        id: AcademicYear.current + relative_year,
        name: AcademicYear.current + relative_year
      )
    end
  end

  def teacher_id_radio_options
    [
      Form::Option.new(
        id: true,
        name: "Enabled"
      ),
      Form::Option.new(
        id: false,
        name: "Disabled"
      )
    ]
  end
end
