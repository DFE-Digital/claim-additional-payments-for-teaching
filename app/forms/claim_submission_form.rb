class ClaimSubmissionForm < Form
  attribute :selected_claim_policy

  validate :not_already_submitted
  validate :email_address_provided
  validate :email_address_verified, if: :email_address_provided?
  validate :mobile_number_verified
  validate :claim_is_eligible

  def save
    return false unless valid?

    # Move more current claim stuff into here then extract it into a job
    current_claim.submit!(selected_claim_policy)

    ClaimMailer.submitted(current_claim.main_claim).deliver_later
    ClaimVerifierJob.perform_later(current_claim.main_claim)
  rescue Claim::NotSubmittable
    # Probably not needed but replicating the existing behaviour
    main_claim.valid?(:submit)
    main_claim.errors.full_messages.each do |message|
      errors.add(:base, message)
    end

    false
  end

  private

  def current_claim
    claim
  end

  # Duplicates knowledge of which claim is being submitted between current
  # claim and here
  def main_claim
    return @main_claim if defined?(@main_claim)

    @main_claim = if selected_claim_policy
      current_claim.for_policy(selected_claim_policy)
    else
      current_claim.main_claim
    end
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

  def claim_is_eligible
    if main_claim.eligibility.ineligible?
      errors.add(:base, "You’re not eligible for this payment")
    end
  end
end
