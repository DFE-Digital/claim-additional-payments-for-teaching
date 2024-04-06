class ClaimSchoolForm < Form
  attribute :claim_school_id

  attr_reader :schools

  validates :claim_school_id, presence: {message: ->(object, data) { object.i18n_errors_path("select_a_school") }}
  validate :claim_school_must_exist, if: -> { claim_school_id.present? }

  def initialize(claim:, journey:, params:)
    super

    load_schools
    self.claim_school_id = permitted_params[:claim_school_id]
  end

  def backlink_path
    params[:slug] if params[:school_search]
  end

  def save
    return false unless valid?

    update!({"eligibility_attributes" => {"claim_school_id" => claim_school_id}})
  end

  def claim_school_name
    claim.eligibility.claim_school_name
  end

  private

  def i18n_form_namespace
    "claim_school"
  end

  def permitted_params
    @permitted_params ||= params.fetch(:claim, {}).permit(:claim_school_id)
  end

  def load_schools
    return unless params[:school_search]

    @schools = School.search(params[:school_search])
  rescue ArgumentError => e
    raise unless e.message == School::SEARCH_NOT_ENOUGH_CHARACTERS_ERROR

    errors.add(:school_search, i18n_errors_path("enter_a_school_or_postcode"))
  end

  def claim_school_must_exist
    unless School.find_by(id: claim_school_id)
      errors.add(:claim_school_id, i18n_errors_path("school_not_found"))
    end
  end
end
