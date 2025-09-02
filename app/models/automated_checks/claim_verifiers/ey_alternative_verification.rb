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

        if bank_details_match?
          data[:bank_details_were_passed_automatically] = true
          data[:bank_details_match] = true
        end

        task = claim.tasks.build(
          name: TASK_NAME,
          data: data
        )

        if failable?
          task.passed = false
          task.manual = false
        elsif passable?
          task.passed = true
          task.manual = false
        end

        task.save!(context: :claim_verifier)
      end

      private

      attr_accessor :claim

      def eligibility
        claim.eligibility
      end

      def existing_task_persisted?
        claim.tasks.any? { |task| task.name == TASK_NAME }
      end

      def personal_details_match?
        eligibility.alternative_idv_claimant_employed_by_nursery == true &&
          eligibility.alternative_idv_claimant_date_of_birth == claim.date_of_birth &&
          eligibility.alternative_idv_claimant_postcode.downcase == claim.postcode.downcase &&
          eligibility.alternative_idv_claimant_national_insurance_number.downcase == claim.national_insurance_number.downcase &&
          eligibility.alternative_idv_claimant_email.downcase == claim.email_address.downcase
      end

      def bank_details_match?
        return false unless eligibility.alternative_idv_claimant_employed_by_nursery == true
        return false unless eligibility.alternative_idv_claimant_bank_details_match
        return false unless claim.hmrc_name_match?
        return false unless banking_names_match?

        true
      end

      def banking_names_match?
        normalised_banking_name = claim.banking_name.strip.downcase
        normalised_first_name = claim.first_name.strip.downcase
        normalised_surname = claim.surname.strip.downcase

        normalised_banking_name.start_with?(normalised_first_name) &&
          normalised_banking_name.end_with?(normalised_surname)
      end

      def passable?
        personal_details_match? && bank_details_match?
      end

      def failable?
        eligibility.alternative_idv_claimant_employed_by_nursery == false
      end
    end
  end
end
