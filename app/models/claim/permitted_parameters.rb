# frozen_string_literal: true

class Claim
  # Used to determine the claim attributes that can be set by the user during
  # the public claim process.
  class PermittedParameters
    attr_reader :claim

    def initialize(claim)
      @claim = claim
    end

    def keys
      claim_attributes << eligibility_attributes
    end

    private

    def claim_attributes
      Claim::EDITABLE_ATTRIBUTES.dup - verified_claim_attributes
    end

    def eligibility_attributes
      {eligibility_attributes: claim.eligibility.class::EDITABLE_ATTRIBUTES.dup}
    end

    def verified_claim_attributes
      claim.verified_fields.map(&:to_sym)
    end
  end
end
