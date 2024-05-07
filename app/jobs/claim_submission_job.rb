class ClaimSubmissionJob < ApplicationJob
  def perform(main_claim:, other_claims:)
    main_claim.submitted_at = Time.zone.now
    main_claim.reference = unique_reference

    eligibility = main_claim.eligibility

    if main_claim.has_ecp_or_lupp_policy?
      eligibility.award_amount = eligibility.calculate_award_amount

      main_claim.policy_options_provided = generate_policy_options_provided(
        main_claim: main_claim,
        other_claims: other_claims
      )
    end

    ActiveRecord::Base.transaction do
      main_claim.save!
      eligibility.save!
      other_claims.each(&:destroy!)
    end

    ClaimMailer.submitted(main_claim).deliver_later
    ClaimVerifierJob.perform_later(main_claim)
  end

  private

  def generate_policy_options_provided(main_claim:, other_claims:)
    claims = [main_claim] + other_claims

    eligible_now_and_sorted(claims).map do |c|
      {
        "policy" => c.policy.to_s,
        "award_amount" => BigDecimal(c.award_amount)
      }
    end
  end

  def eligible_now_and_sorted(claims)
    eligible_now(claims).sort_by do |c|
      [-c.award_amount.to_i, c.policy.short_name]
    end
  end

  def eligible_now(claims)
    claims.select { |c| c.eligibility.status == :eligible_now }
  end

  def unique_reference
    loop {
      ref = Reference.new.to_s
      break ref unless Claim.exists?(reference: ref)
    }
  end
end
