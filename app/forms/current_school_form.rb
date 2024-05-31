class CurrentSchoolForm < Form
  attribute :current_school_id

  attr_reader :schools

  validates :current_school_id, presence: {message: i18n_error_message(:select_the_school_you_teach_at)}
  validate :current_school_must_be_open, if: -> { current_school_id.present? }

  def initialize(claim:, journey_session:, journey:, params:)
    super

    load_schools
  end

  def save
    return false unless valid?

    update!({"eligibility_attributes" => {"current_school_id" => current_school_id}})
  end

  def current_school_name
    claim.eligibility.current_school_name
  end

  def no_search_results?
    params[:school_search].present? && errors.empty?
  end

  private

  def load_schools
    return unless params[:school_search]

    @schools = School.open.search(params[:school_search])
  rescue ArgumentError => e
    raise unless e.message == School::SEARCH_NOT_ENOUGH_CHARACTERS_ERROR

    errors.add(:school_search, i18n_errors_path("enter_a_school_or_postcode"))
  end

  def current_school_must_be_open
    if (school = School.find_by(id: current_school_id))
      errors.add(:current_school_id, i18n_errors_path("the_selected_school_is_closed")) unless school.open?
    else
      errors.add(:current_school_id, i18n_errors_path("school_not_found"))
    end
  end
end
