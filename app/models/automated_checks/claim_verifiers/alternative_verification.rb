module AutomatedChecks
  module ClaimVerifiers
    class AlternativeVerification
      def initialize(claim:)
        @claim = claim
      end

      def perform
        return if existing_task_persisted?

        data = {}

        if personal_details_match?
          data[:personal_details_task_completed_automatically] = true
          data[:personal_details_match] = true
        elsif personal_details_failable?
          data[:personal_details_task_completed_automatically] = true
          data[:personal_details_match] = false
        end

        if bank_details_match?
          data[:bank_details_task_completed_automatically] = true
          data[:bank_details_match] = true
        elsif bank_details_failable?
          data[:bank_details_task_completed_automatically] = true
          data[:bank_details_match] = false
        end

        task = claim.tasks.build(
          name: task_name,
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

      def task_name
        self.class::TASK_NAME
      end

      def eligibility
        claim.eligibility
      end

      def existing_task_persisted?
        claim.tasks.any? { |task| task.name == task_name }
      end

      def personal_details_match?
        raise NotImplementedError, "Subclasses must implement personal_details_match?"
      end

      def bank_details_match?
        return false if personal_details_failable?
        return false if bank_details_failable?
        return false unless claim.hmrc_name_match?
        return false unless banking_names_match?

        true
      end

      def banking_names_match?
        normalised_banking_name = claim.banking_name.strip.downcase
        normalised_claim_name = claim.full_name.strip.downcase

        normalised_banking_name == normalised_claim_name
      end

      def passable?
        personal_details_match? && bank_details_match?
      end

      def personal_details_failable?
        raise NotImplementedError, "Subclasses must implement personal_details_failable?"
      end

      def bank_details_failable?
        raise NotImplementedError, "Subclasses must implement bank_details_failable?"
      end

      def failable?
        personal_details_failable? || bank_details_failable?
      end
    end
  end
end
