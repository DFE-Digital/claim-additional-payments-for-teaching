class ClaimSubmissionForm < Form
  attribute :selected_claim_policy, :string

  validate :not_already_submitted
  validate :email_address_provided
  validate :email_address_verified, if: :email_address_provided?
  validate :mobile_number_verified
  validate :main_claim_is_eligible
  validate :main_claim_is_submittable

  def save
    return false unless valid?

    ClaimSubmissionService.call(
      main_claim: main_claim,
      other_claims: other_claims
    )

    true
  end

  def main_claim
    return @main_claim if defined?(@main_claim)

    if selected_claim_policy
      current_claim.for_policy(selected_claim_policy)
    else
      current_claim.main_claim
    end
  end

  def other_claims
    current_claim.claims - [main_claim]
  end

  private

  def current_claim
    claim
  end

  def not_already_submitted
    if main_claim.submitted?
      errors.add(:base, "This claim has already been submitted")
    end
  end

  def email_address_provided
    unless email_address_provided?
      errors.add(:base, "Enter an email address")
    end
  end

  def email_address_provided?
    main_claim.email_address.present?
  end

  def email_address_verified
    unless main_claim.email_verified?
      errors.add(
        :base,
        "You must verify your email address before you can submit your claim"
      )
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
    main_claim.send(:submittable_mobile_details?)
  end

  def main_claim_is_eligible
    if main_claim.eligibility.ineligible?
      errors.add(:base, "You’re not eligible for this payment")
    end
  end

  # Probably not needed but replicating the existing behaviour
  def main_claim_is_submittable
    return if main_claim.valid?(:submit)

    main_claim.errors.full_messages.each { |message| errors.add(:base, message) }
  end
end
