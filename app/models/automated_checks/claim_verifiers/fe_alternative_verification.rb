module AutomatedChecks
  module ClaimVerifiers
    class FeAlternativeVerification < AlternativeVerification
      TASK_NAME = "fe_alternative_verification".freeze

      private

      def personal_details_match?
        claim.eligibility.provider_verification_claimant_employed_by_college == true &&
          claim.eligibility.provider_verification_claimant_date_of_birth == claim.date_of_birth &&
          claim.eligibility.provider_verification_claimant_postcode.downcase == claim.postcode.downcase &&
          claim.eligibility.provider_verification_claimant_national_insurance_number == claim.national_insurance_number &&
          claim.eligibility.provider_verification_claimant_email.downcase == claim.eligibility.work_email.downcase
      end

      def personal_details_failable?
        claim.eligibility.provider_verification_claimant_employed_by_college == false
      end

      def bank_details_failable?
        claim.eligibility.provider_verification_claimant_bank_details_match == false
      end
    end
  end
end
