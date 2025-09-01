# THINK WE CAN LOSE THIS
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

        if passable?
          create_task(passed: true)
        end

        if failable?
          create_task(passed: false)
        end
      end

      private

      attr_accessor :claim

      def existing_task_persisted?
        claim.tasks.any? { |task| task.name == TASK_NAME }
      end

      def create_task(passed:)
        task = claim.tasks.build(
          {
            name: TASK_NAME,
            passed:,
            manual: false
          }
        )

        task.save!(context: :claim_verifier)

        task
      end

      def passable?
        claim.eligibility.alternative_idv_claimant_employed_by_nursery == true &&
          claim.eligibility.alternative_idv_claimant_date_of_birth == claim.date_of_birth &&
          claim.eligibility.alternative_idv_claimant_postcode == claim.postcode &&
          claim.eligibility.alternative_idv_claimant_national_insurance_number == claim.national_insurance_number &&
          claim.eligibility.alternative_idv_claimant_email == claim.email_address &&
          claim.eligibility.alternative_idv_claimant_bank_details_match == true
      end

      def failable?
        claim.eligibility.alternative_idv_claimant_employed_by_nursery == false
      end
    end
  end
end
