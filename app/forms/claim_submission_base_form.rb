class ClaimSubmissionBaseForm
  include ActiveModel::Model
  include FormHelpers

  attr_reader :journey_session, :claim

  validate :not_already_submitted
  validate :email_address_is_present, if: :claim_expected_to_have_email_address
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
      claim.save!
      mark_service_access_code_as_used!
    end

    claim.policy.mailer.submitted(claim).deliver_later
    ClaimVerifierJob.perform_later(claim)

    true
  end

  private

  delegate :answers, to: :journey_session

  def main_eligibility
    @main_eligibility ||= eligibilities.first
  end

  def build_claim
    Claim.new.tap do |claim|
      claim.eligibility ||= main_eligibility
      claim.started_at = journey_session.created_at
      answers.attributes.each do |name, value|
        if claim.respond_to?(:"#{name}=")
          claim.public_send(:"#{name}=", value)
        end
      end
    end
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
    claim.journey_session = journey_session
    claim.policy_options_provided = generate_policy_options_provided
    claim.reference ||= generate_reference
    set_submitted_at_attributes
  end

  def mark_service_access_code_as_used!
    access_code = Journeys::ServiceAccessCode.find_by(
      code: answers.service_access_code,
      journey: journey_session.journey_class
    )
    access_code&.mark_as_used!
  end

  def set_submitted_at_attributes
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
      errors.add(:base, i18n_errors_path(:already_submitted))
    end
  end

  def email_address_is_present
    if answers.email_address.blank?
      errors.add(:email_address, i18n_errors_path(:email_address))
    end
  end

  def email_address_verified
    return unless answers.email_address.present?

    unless answers.email_verified
      errors.add(:email_verified, i18n_errors_path(:email_verified))
    end
  end

  def mobile_number_verified
    unless mobile_number_verified?
      errors.add(
        :base,
        i18n_errors_path(:mobile_number_verified)
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
    if claim.eligibility.policy::PolicyEligibilityChecker.new(answers: answers).ineligible?
      errors.add(:base, i18n_errors_path(:ineligible))
    end
  end

  def main_claim_is_submittable
    return if claim.valid?(:submit)
    claim.errors.full_messages.each { |message| errors.add(:base, message) }
  end

  def journey
    self.class.module_parent
  end

  def claim_expected_to_have_email_address
    true
  end
end
