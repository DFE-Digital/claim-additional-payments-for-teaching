module AutomatedChecks
  module ClaimVerifiers
    # This task is automatically passed if none of the conditions detected:
    #   * teaching_start_year_mismatch?
    #     * Year 2 if a year 1 claim start_year was 2020 so NOT eligible in Year 2 (more than 5 years)
    #     * Year 3+ claims, check most recent approved claim in previous years
    #       and if the start_year is different to the answer they gave this year
    #
    #   * previous_claim_rejected_due_to_start_year_mismatch?
    #     * Year 2 check Year 1 (or Year 3+ check most recent claimed year) had rejected claim
    #       where the provider verified false they starting teaching within the last 5 years
    #
    # If detected the Task is incomplete and needs a manual check.

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

          if previous_claim_rejected_due_to_start_year_mismatch?
            passed = nil
            create_start_year_matches_claim_false_note
          end

          if passed
            create_task(passed:)
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

      def create_start_year_matches_claim_false_note
        eligibility = claim.eligibility
        previous_claim_year = eligibility.previous_claim_year

        claims = eligibility.rejected_claims_for_academic_year_with_start_year_matches_claim_false(
          previous_claim_year
        )

        body = "Claimant was previously rejected in #{claims.first.academic_year} following provider verification indicating " \
          "over 5 years of employment in Further Education with claim reference(s): #{claims.pluck(:reference).join(", ")}"

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

      def previous_claim_rejected_due_to_start_year_mismatch?
        !!claim.eligibility.flagged_as_previously_start_year_matches_claim_false
      end
    end
  end
end
