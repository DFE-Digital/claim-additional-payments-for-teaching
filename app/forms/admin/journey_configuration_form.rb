class Admin::JourneyConfigurationForm
  include ActiveModel::Model
  include ActiveModel::Attributes

  attribute :journey_configuration
  attribute :current_academic_year, AcademicYear::Type.new
  attribute :open_for_submissions, :boolean
  attribute :availability_message, :string
  attribute :teacher_id_enabled, :boolean
  attribute :close_at, :datetime
  attribute :automatic_approvals, :boolean
  attribute :approved_min_qa_threshold, :integer
  attribute :rejected_min_qa_threshold, :integer

  validates :close_at, presence: true, if: :open_for_submissions
  validate :close_at_in_future, if: :open_for_submissions

  validates :approved_min_qa_threshold,
    numericality: {
      greater_than_or_equal_to: 0,
      less_than_or_equal_to: 100
    }

  validates :rejected_min_qa_threshold,
    numericality: {
      greater_than_or_equal_to: 0,
      less_than_or_equal_to: 100
    }

  def self.for_journey_configuration(journey_configuration)
    new(
      journey_configuration:,
      current_academic_year: journey_configuration.current_academic_year,
      open_for_submissions: journey_configuration.open_for_submissions,
      availability_message: journey_configuration.availability_message,
      teacher_id_enabled: journey_configuration.teacher_id_enabled,
      close_at: journey_configuration.close_at,
      automatic_approvals: journey_configuration.automatic_approvals,
      approved_min_qa_threshold: journey_configuration.approved_min_qa_threshold,
      rejected_min_qa_threshold: journey_configuration.rejected_min_qa_threshold
    )
  end

  def academic_year_select_options
    (-1..3).map do |relative_year|
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

  def automatic_approvals_radio_options
    [
      Form::Option.new(
        id: true,
        name: "On"
      ),
      Form::Option.new(
        id: false,
        name: "Off"
      )
    ]
  end

  def save
    return false if invalid?

    journey_configuration.update(
      current_academic_year:,
      open_for_submissions:,
      availability_message:,
      teacher_id_enabled:,
      close_at:,
      automatic_approvals:,
      approved_min_qa_threshold:,
      rejected_min_qa_threshold:
    )
  end

  private

  def close_at_in_future
    return if close_at.blank?
    return if close_at > Time.current.in_time_zone("London")

    errors.add(:close_at, "must be in the future")
  end
end
