class ClaimSubmissionBaseForm
  include ActiveModel::Model

  attr_reader :journey_session, :claim

  validate :not_already_submitted
  validate :email_address_is_preesent
  validate :email_address_verified
  validate :mobile_number_verified
  validate :claim_is_eligible
  validate :main_claim_is_submittable

  def initialize(journey_session:)
    @journey_session = journey_session
    @claim = build_claim
  end

  def save
    return false unless valid?

    ApplicationRecord.transaction do
      set_attributes_for_claim_submission
      main_eligibility.save!
      claim.save!
    end

    ClaimMailer.submitted(claim).deliver_later
    ClaimVerifierJob.perform_later(claim)
  end

  private

  delegate :answers, to: :journey_session

  def build_claim
    claim = Claim.new

    claim.eligibility = main_eligibility

    answers.attributes.each do |name, value|
      if claim.respond_to?(:"#{name}=")
        claim.public_send(:"#{name}=", value)
      end
    end

    claim
  end

  def eligibilities
    @eligibilities ||= journey::POLICIES.map do |policy|
      policy::Eligibility.new.tap do |eligibility|
        set_eligibility_attributes(eligibility)
        calculate_award_amount(eligibility)
      end
    end
  end

  def set_eligibility_attributes(eligibility)
    answers.attributes.each do |name, value|
      if eligibility.respond_to?(:"#{name}=")
        eligibility.public_send(:"#{name}=", value)
      end
    end
  end

  def set_attributes_for_claim_submission
    # Temp conditional while we're working with the shim
    claim.journey_session = if journey_session.is_a?(ClaimJourneySessionShim)
      journey_session.journey_session
    else
      journey_session
    end
    claim.policy_options_provided = generate_policy_options_provided
    claim.reference = generate_reference
    claim.submitted_at = Time.zone.now
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

  def email_address_is_preesent
    if answers.email_address.blank?
      errors.add(:email_address, i18n_error_message(:email_address))
    end
  end

  def email_address_verified
    return unless answers.email_address.present?

    unless answers.email_verified
      errors.add(:email_verified, i18n_error_message(:email_verified))
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

  def mobile_number_verified?
    return true if answers.using_mobile_number_from_tid?
    return true if answers.provide_mobile_number && answers.mobile_number.present? && answers.mobile_verified == true
    return true if answers.provide_mobile_number == false && answers.mobile_number.nil? && answers.mobile_verified == false
    return true if answers.provide_mobile_number == false && answers.mobile_verified.nil?

    false
  end

  def claim_is_eligible
    if eligibility_checker.ineligible?
      errors.add(:base, i18n_error_message(:ineligible))
    end
  end

  def main_claim_is_submittable
    return if claim.valid?(:submit)
    claim.errors.full_messages.each { |message| errors.add(:base, message) }
  end

  def i18n_error_message(attr)
    I18n.t("#{journey::I18N_NAMESPACE}.forms.claim_submission_form.errors.#{attr}")
  end

  def journey
    self.class.module_parent
  end
end
