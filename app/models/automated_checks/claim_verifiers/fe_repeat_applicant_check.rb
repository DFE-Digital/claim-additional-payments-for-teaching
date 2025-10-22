module AutomatedChecks
  module ClaimVerifiers
    class FeRepeatApplicantCheck
      TASK_NAME = "fe_repeat_applicant_check".freeze
      private_constant :TASK_NAME

      def initialize(claim:)
        self.claim = claim
      end

      def perform
        return if existing_task_persisted?

        ActiveRecord::Base.transaction do
          passed = true

          if teaching_start_year_mismatch?
            passed = nil
            create_start_year_mismatch_note
          end

          if passed
            create_task(passed:)
            claim.eligibility.update!(repeat_applicant_check_passed: true)
          end
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

      def create_start_year_mismatch_note
        previous_approved_claim = claim.eligibility.previous_approved_claim

        body = if Policies::FurtherEducationPayments.year_2_claim?(claim)
          "Year 1 claim exists for claimant with teaching start year 2020/2021 " \
          "with claim reference: #{previous_approved_claim.reference}"
        else
          "Teaching start year does not match approved claim start year from a previous academic year " \
          "with claim reference: #{previous_approved_claim.reference}"
        end

        claim.notes.create!(
          {
            body: body,
            label: TASK_NAME
          }
        )
      end

      def teaching_start_year_mismatch?
        !!claim.eligibility.flagged_as_mismatch_on_teaching_start_year
      end
    end
  end
end
