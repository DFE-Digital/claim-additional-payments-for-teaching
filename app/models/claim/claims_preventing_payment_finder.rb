class Claim
  class ClaimsPreventingPaymentFinder
    attr_reader :claim

    def initialize(claim)
      @claim = claim
    end

    # Returns a list of claims which prevent us from adding `claim` to the
    # payroll run for the current month.
    #
    # These claims are payrollable, and submitted by the same claimant as
    # `claim`, as identified by teacher reference number (TRN).
    #
    # The returned claims have different payment or tax details to those
    # provided by `claim`, and hence `claim` cannot be paid in the same payment
    # as the returned claims.
    #
    # NOTE: This only works for ECP/LUPP and TSLR cross policy as this requires a TRN
    # Driven by: Policies.policies_claimable(policy) using OTHER_CLAIMABLE_POLICIES config otherwise this just returns []
    def claims_preventing_payment
      @claims_preventing_payment ||= find_claims_preventing_payment
    end

    private

    def find_claims_preventing_payment
      eligibility_ids = claim.policy.policies_claimable.map { |policy|
        policy::Eligibility.where(teacher_reference_number: claim.eligibility.teacher_reference_number)
      }.flatten.map(&:id)

      payrollable_claims_from_same_claimant = Claim.payrollable.where(eligibility_id: eligibility_ids)

      payrollable_topup_claims_from_same_claimant = Topup.includes(:claim).payrollable
        .select { |t|
        claim.policy.policy_eligibilities_claimable.map(&:to_s).include?(t.claim.eligibility_type) &&
          t.claim.eligibility.teacher_reference_number == claim.eligibility.teacher_reference_number
      }
        .map(&:claim)

      [payrollable_claims_from_same_claimant, payrollable_topup_claims_from_same_claimant].reduce([], :concat).select do |other_claim|
        Payment::PERSONAL_CLAIM_DETAILS_ATTRIBUTES_FORBIDDING_DISCREPANCIES.any? do |attribute|
          attribute_does_not_match?(other_claim, attribute)
        end
      end
    end

    def attribute_does_not_match?(claim_to_compare, attribute)
      compare_attribute_value = claim_to_compare.read_attribute(attribute)
      attribute_value = claim.read_attribute(attribute)

      return false if [compare_attribute_value, attribute_value].all?(&:blank?)

      compare_attribute_value != attribute_value
    end
  end
end
