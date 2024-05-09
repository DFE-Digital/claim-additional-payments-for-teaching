class ClaimSubmissionForm
  include ActiveModel::Model
  include ActiveModel::Attributes

  attribute :selected_policy, :string

  ECP_OR_LUPP_POLICIES = [
    Policies::EarlyCareerPayments,
    Policies::LevellingUpPremiumPayments
  ]

  CLAIM_ATTRIBUTES = [
    [:address_line_1, :string],
    [:address_line_2, :string],
    [:address_line_3, :string],
    [:address_line_4, :string],
    [:postcode, :string],
    [:date_of_birth, :date],
    [:teacher_reference_number, :string],
    [:national_insurance_number, :string],
    [:email_address, :string],
    [:bank_sort_code, :string],
    [:bank_account_number, :string],
    [:details_check, :boolean],
    [:payroll_gender, :string],
    [:first_name, :string],
    [:middle_name, :string],
    [:surname, :string],
    [:banking_name, :string],
    [:building_society_roll_number, :string],
    [:academic_year, AcademicYear::Type.new],
    [:bank_or_building_society, :integer],
    [:provide_mobile_number, :boolean],
    [:mobile_number, :string],
    [:email_verified, :boolean],
    [:mobile_verified, :boolean],
    [:hmrc_bank_validation_succeeded, :boolean],
    [:hmrc_bank_validation_responses, nil], # , :json
    [:logged_in_with_tid, :boolean],
    [:teacher_id_user_info, nil], # :json
    [:email_address_check, :boolean],
    [:mobile_check, :string],
    [:qualifications_details_check, :boolean]
  ]

  CLAIM_ATTRIBUTES.each do |name, type|
    attribute name, type
  end

  ADDITIONAL_PAYMENTS_ELIGIBILITY_ATTRIBUTES = [
    [:nqt_in_academic_year_after_itt, :boolean],
    [:employed_as_supply_teacher, :boolean],
    [:qualification, :string],
    [:has_entire_term_contract, :boolean],
    [:employed_directly, :boolean],
    [:subject_to_disciplinary_action, :boolean],
    [:subject_to_formal_performance_action, :boolean],
    [:eligible_itt_subject, :string],
    [:eligible_degree_subject, :string],
    [:teaching_subject_now, :boolean],
    [:itt_academic_year, AcademicYear::Type.new],
    [:current_school_id, :string], # uuid
    [:induction_completed, :boolean],
    [:school_somewhere_else, :boolean]
  ]

  STUDENT_LOANS_ELIGIBILITY_ATTRIBUTES = [
    [:qts_award_year, :string],
    [:claim_school_id, :string], # uuid
    [:current_school_id, :string], # uuid
    [:employment_status, :string],
    [:biology_taught, :boolean],
    [:chemistry_taught, :boolean],
    [:computing_taught, :boolean],
    [:languages_taught, :boolean],
    [:physics_taught, :boolean],
    [:taught_eligible_subjects, :boolean],
    [:student_loan_repayment_amount, :decimal],
    [:had_leadership_position, :boolean],
    [:mostly_performed_leadership_duties, :boolean],
    [:claim_school_somewhere_else, :boolean]
  ]

  ELIGIBILITY_ATTRIBUTES = ADDITIONAL_PAYMENTS_ELIGIBILITY_ATTRIBUTES + STUDENT_LOANS_ELIGIBILITY_ATTRIBUTES

  ELIGIBILITY_ATTRIBUTES.each do |name, type|
    attribute name, type
  end

  validate :not_already_submitted
  validates :email_address, presence: {message: "Enter an email address"}
  validates :email_verified,
    inclusion: {
      in: [true],
      message: "You must verify your email address before you can submit your claim"
    },
    if: -> { email_address.present? }
  validate :mobile_number_verified

  validate :claim_is_eligible
  validate :main_claim_is_submittable

  def initialize(journey_session:)
    @journey_session = journey_session

    super(journey_session.answers)
  end

  def save
    return false unless valid?

    ApplicationRecord.transaction do
      main_eligibility.save!
      claim.save!
    end

    ClaimMailer.submitted(claim).deliver_later
    ClaimVerifierJob.perform_later(claim)
  end

  def claim
    @claim ||= build_claim
  end

  private

  attr_reader :journey_session

  def journey
    journey_session.journey_module
  end

  def build_claim
    claim = Claim.new

    # Temp conditional while we're working with the shim
    claim.journeys_session = if journey_session.is_a?(ClaimJourneySessionShim)
      journey_session.journey_session
    else
      journey_session
    end

    claim.eligibility = main_eligibility

    CLAIM_ATTRIBUTES.map(&:first).each do |attribute_name|
      claim.public_send(:"#{attribute_name}=", public_send(attribute_name))
    end

    claim.policy_options_provided = generate_policy_options_provided
    claim.reference = generate_reference
    claim.submitted_at = Time.zone.now
    claim
  end

  def main_eligibility
    @main_eligibility ||= eligibilities.detect { |e| e.policy == main_policy }
  end

  # The "main" policy should always be:
  # - The one and only one available for non-combined journeys
  # - The one from the claim type selected at the end of combined eligibility
  #   journeys
  # - ECP for ECP/LUP until one is selected at the end of the eligibility
  #   journey
  # It should raise otherwise; this may need to be updated for future
  # combined journeys.
  def main_policy
    if single_policy_journey?
      journey::POLICIES.first
    elsif selected_claim_policy.present?
      selected_claim_policy
    elsif ecp_or_lupp_claims?
      Policies::EarlyCareerPayments
    else
      raise UnselectablePolicyError
    end
  end

  def single_policy_journey?
    journey::POLICIES.one?
  end

  def selected_claim_policy
    if selected_policy.present?
      "Policies::#{selected_policy}".constantize
    end
  end

  def ecp_or_lupp_claims?
    journey::POLICIES.any? do |policy|
      ECP_OR_LUPP_POLICIES.include?(policy)
    end
  end

  def eligibilities
    @eligibilities ||= journey::POLICIES.map do |policy|
      policy::Eligibility.new.tap do |eligibility|
        set_eligibility_attributes(eligibility)
        calculate_reward_amount(eligibility)
      end
    end
  end

  def set_eligibility_attributes(eligibility)
    ELIGIBILITY_ATTRIBUTES.map(&:first).each do |attribute_name|
      setter = "#{attribute_name}="
      # Not all eligibilities have the same fields
      if eligibility.respond_to?(setter)
        eligibility.public_send(setter, public_send(attribute_name))
      end
    end
  end

  def calculate_reward_amount(eligibility)
    if eligibility.has_attribute?(:award_amount)
      eligibility.award_amount = eligibility.calculate_award_amount
    end
  end

  def generate_reference
    loop {
      ref = Reference.new.to_s
      break ref unless Claim.exists?(reference: ref)
    }
  end

  def generate_policy_options_provided
    return [] unless ecp_or_lupp_claims?

    eligible_now_and_sorted.map do |e|
      {
        "policy" => e.policy.to_s,
        "award_amount" => BigDecimal(e.award_amount)
      }
    end
  end

  def eligible_now_and_sorted
    eligible_now.sort_by { |e| [-e.award_amount.to_i, e.policy.short_name] }
  end

  def eligible_now
    eligibilities.select { |e| e.status == :eligible_now }
  end

  def not_already_submitted
    if journey_session.submitted?
      errors.add(:base, "You have already submitted this claim")
    end
  end

  def mobile_number_verified
    unless mobile_number_verified?
      errors.add(
        :base,
        "You must verify your mobile number before you can submit your claim"
      )
    end
  end

  # TODO RL move the logic out of the claim rather than use send
  def mobile_number_verified?
    claim.send(:submittable_mobile_details?)
  end

  def claim_is_eligible
    if main_eligibility.ineligible?
      errors.add(:base, "You’re not eligible for this payment")
    end
  end

  def main_claim_is_submittable
    return if claim.valid?(:submit)
    claim.errors.full_messages.each { |message| errors.add(:base, message) }
  end
end
