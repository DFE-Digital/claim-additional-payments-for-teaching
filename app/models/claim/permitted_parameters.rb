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
      Claim::EDITABLE_ATTRIBUTES.dup - claim_attributes_from_govuk_verify
    end

    def eligibility_attributes
      {eligibility_attributes: claim.eligibility.class::EDITABLE_ATTRIBUTES.dup}
    end

    def claim_attributes_from_govuk_verify
      claim.govuk_verify_fields.map(&:to_sym)
    end
  end
end
