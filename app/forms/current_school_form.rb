class CurrentSchoolForm < Form
  attribute :current_school_id
  attribute :change_school

  attr_reader :schools

  validates :current_school_id, presence: {message: i18n_error_message(:select_the_school_you_teach_at)}
  validate :current_school_must_be_open, if: -> { current_school_id.present? }

  def initialize(journey_session:, journey:, params:, session: {})
    super

    load_schools
  end

  def save
    return false unless valid?

    journey_session.answers.assign_attributes(current_school_id:)
    journey_session.save!
  end

  delegate :name, to: :current_school, prefix: true, allow_nil: true

  def no_search_results?
    params[:school_search].present? && errors.empty?
  end

  private

  def current_school
    @current_school ||= School.find_by(id: current_school_id)
  end

  def load_schools
    return unless params[:school_search]

    @schools = School.open.search(params[:school_search])
  rescue ArgumentError => e
    raise unless e.message == School::SEARCH_NOT_ENOUGH_CHARACTERS_ERROR

    errors.add(:school_search, i18n_errors_path("enter_a_school_or_postcode"))
  end

  def current_school_must_be_open
    if current_school
      errors.add(:current_school_id, i18n_errors_path("the_selected_school_is_closed")) unless current_school.open?
    else
      errors.add(:current_school_id, i18n_errors_path("school_not_found"))
    end
  end
end
