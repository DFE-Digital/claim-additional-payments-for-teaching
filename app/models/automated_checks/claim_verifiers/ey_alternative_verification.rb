module AutomatedChecks
  module ClaimVerifiers
    class EyAlternativeVerification < AlternativeVerification
      TASK_NAME = "ey_alternative_verification".freeze

      private

      def personal_details_match?
        eligibility.alternative_idv_claimant_employed_by_nursery == true &&
          eligibility.alternative_idv_claimant_date_of_birth == claim.date_of_birth &&
          eligibility.alternative_idv_claimant_postcode.downcase == claim.postcode.downcase &&
          eligibility.alternative_idv_claimant_national_insurance_number.downcase == claim.national_insurance_number.downcase &&
          eligibility.alternative_idv_claimant_email.downcase == claim.email_address.downcase
      end

      def personal_details_failable?
        eligibility.alternative_idv_claimant_employed_by_nursery == false
      end

      def bank_details_failable?
        eligibility.alternative_idv_claimant_bank_details_match == false
      end
    end
  end
end
