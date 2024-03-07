class CurrentSchoolForm < Form
  attribute :school_search
  attribute :current_school_id

  attr_reader :schools

  validates :current_school_id, presence: {message: ->(object, data) { object.i18n_errors_path("select_the_school_you_teach_at") }}
  validate :current_school_must_be_open, if: -> { current_school_id.present? }

  def initialize(claim:, journey:, params:)
    super

    load_schools
    self.current_school_id = permitted_params[:current_school_id]
  end

  def backlink_path
    params[:slug] if params[:school_search]
  end

  def save
    return false unless valid?

    claim.update!({eligibility_attributes: {current_school_id: current_school_id}})
  end

  def current_school_name
    claim.eligibility.current_school_name
  end

  def i18n_errors_path(msg)
    I18n.t("#{view_path}.forms.current_school.errors.#{msg}")
  end

  private

  def permitted_params
    @permitted_params ||= params.fetch(:claim, {}).permit(:current_school_id)
  end

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
