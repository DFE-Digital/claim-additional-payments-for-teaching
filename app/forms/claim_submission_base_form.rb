class ClaimSubmissionBaseForm
  include ActiveModel::Model
  include ActiveModel::Attributes

  attribute :selected_policy, :string

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

  validate :not_already_submitted

  validates :email_address,
    presence: {
      message: ->(form, _) { form.i18n_error_message(:email_address) }
    }

  validates :email_verified,
    inclusion: {
      in: [true],
      message: ->(form, _) { form.i18n_error_message(:email_verified) }
    },
    if: -> { email_address.present? }

  validate :mobile_number_verified

  validate :claim_is_eligible
  validate :main_claim_is_submittable

  def initialize(journey_session:)
    @journey_session = journey_session

    attrs = journey_session
      .answers
      .with_indifferent_access
      .slice(
        *claim_attribute_names,
        *eligibility_attribute_names,
        :selected_policy
      )

    super(attrs)
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

  def i18n_error_message(attr)
    I18n.t("#{i18n_namespace}.forms.claim_submission_form.errors.#{attr}")
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

    claim_attribute_names.each do |attribute_name|
      claim.public_send(:"#{attribute_name}=", public_send(attribute_name))
    end

    claim.policy_options_provided = generate_policy_options_provided
    claim.reference = generate_reference
    claim.submitted_at = Time.zone.now
    claim
  end

  def claim_attribute_names
    CLAIM_ATTRIBUTES.map(&:first)
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
    eligibility_attribute_names.each do |attribute_name|
      setter = "#{attribute_name}="
      # Not all eligibilities have the same fields
      if eligibility.respond_to?(setter)
        eligibility.public_send(setter, public_send(attribute_name))
      end
    end
  end

  def generate_reference
    loop {
      ref = Reference.new.to_s
      break ref unless Claim.exists?(reference: ref)
    }
  end

  def not_already_submitted
    if journey_session.submitted?
      errors.add(:base, i18n_error_message(:already_submitted))
    end
  end

  def mobile_number_verified
    unless mobile_number_verified?
      errors.add(
        :base,
        i18n_error_message(:mobile_number_verified)
      )
    end
  end

  # TODO RL move the logic out of the claim rather than use send
  def mobile_number_verified?
    claim.send(:submittable_mobile_details?)
  end

  def claim_is_eligible
    if main_eligibility.ineligible?
      errors.add(:base, i18n_error_message(:ineligible))
    end
  end

  def main_claim_is_submittable
    return if claim.valid?(:submit)
    claim.errors.full_messages.each { |message| errors.add(:base, message) }
  end
end
