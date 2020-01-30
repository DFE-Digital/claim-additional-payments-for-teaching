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
    def claims_preventing_payment
      @claims_preventing_payment ||= find_claims_preventing_payment
    end

    private

    def find_claims_preventing_payment
      payrollable_claims_from_same_claimant = Claim.payrollable.where(teacher_reference_number: claim.teacher_reference_number)

      payrollable_claims_from_same_claimant.select do |other_claim|
        Payment::PERSONAL_DETAILS_ATTRIBUTES_FORBIDDING_DISCREPANCIES.any? do |attribute|
          attribute_does_not_match?(other_claim, attribute)
        end
      end
    end

    def attribute_does_not_match?(claim_to_compare, attribute)
      claim_to_compare.read_attribute(attribute) != claim.read_attribute(attribute)
    end
  end
end
