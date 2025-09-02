module AutomatedChecks
  module ClaimVerifiers
    class EyAlternativeVerification
      TASK_NAME = "ey_alternative_verification".freeze
      private_constant :TASK_NAME

      def initialize(claim:)
        self.claim = claim
      end

      def perform
        return if existing_task_persisted?

        data = {}

        if personal_details_match?
          data[:personal_details_were_passed_automatically] = true
          data[:personal_details_match] = true
        end

        task = claim.tasks.build(
          name: TASK_NAME,
          data: data
        )

        if failable?
          task.passed = false
          task.manual = false
        end

        task.save!(context: :claim_verifier)
      end

      private

      attr_accessor :claim

      def existing_task_persisted?
        claim.tasks.any? { |task| task.name == TASK_NAME }
      end

      def personal_details_match?
        claim.eligibility.alternative_idv_claimant_employed_by_nursery == true &&
          claim.eligibility.alternative_idv_claimant_date_of_birth == claim.date_of_birth &&
          claim.eligibility.alternative_idv_claimant_postcode.downcase == claim.postcode.downcase &&
          claim.eligibility.alternative_idv_claimant_national_insurance_number.downcase == claim.national_insurance_number.downcase &&
          claim.eligibility.alternative_idv_claimant_email.downcase == claim.email_address.downcase
      end

      def failable?
        claim.eligibility.alternative_idv_claimant_employed_by_nursery == false
      end
    end
  end
end
