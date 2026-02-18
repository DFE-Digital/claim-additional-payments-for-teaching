module AutomatedChecks
  module ClaimVerifiers
    class FeProviderVerificationV2
      TASK_NAME = "fe_provider_verification_v2".freeze

      attr_reader :claim
      delegate :eligibility, to: :claim

      def initialize(claim)
        @claim = claim
      end

      def perform
        return if task_already_persisted?

        if passable?
          create_task(passed: true)
        elsif failed_checks.any?
          create_task(passed: false, data: {failed_checks: failed_checks})
        end
      end

      private

      def create_task(passed:, data: nil)
        task = claim.tasks.build(
          {
            name: TASK_NAME,
            claim_verifier_match: nil,
            passed: passed,
            manual: false,
            data: data
          }
        )

        task.save!(context: :claim_verifier)

        task
      end

      def passable?
        failed_checks.empty? &&
          provider_confirms_claimant_answers? &&
          provider_indicates_no_measures? &&
          provider_indicates_claimant_is_interested_in_becoming_qualified?
      end

      def provider_confirms_claimant_answers?
        eligibility.provider_verification_teaching_responsibilities == true &&
          eligibility.claimant_and_provider_teaching_start_year_match? &&
          eligibility.provider_verification_half_teaching_hours == true &&
          eligibility.provider_verification_half_timetabled_teaching_time == true &&
          eligibility.provider_verification_continued_employment == true &&
          eligibility.provider_verification_contract_type == eligibility.contract_type
      end

      def provider_indicates_no_measures?
        eligibility.provider_verification_performance_measures == false &&
          eligibility.provider_verification_disciplinary_action == false
      end

      def provider_indicates_claimant_is_interested_in_becoming_qualified?
        eligibility.provider_verification_teaching_qualification != "no_not_planned"
      end

      def failed_checks
        return @failed_checks if defined?(@failed_checks)

        @failed_checks = []

        if eligibility.provider_verification_teaching_responsibilities == false
          @failed_checks << "no_teaching_responsibilities"
        end

        if !eligibility.claimant_and_provider_teaching_start_year_match?
          @failed_checks << "teaching_start_year_mismatch"
        end

        if eligibility.provider_verification_half_teaching_hours == false
          @failed_checks << "incorrect_age_range_taught"
        end

        if eligibility.provider_verification_half_timetabled_teaching_time == false
          @failed_checks << "does_not_teach_claimed_courses"
        end

        if eligibility.provider_verification_performance_measures == true
          @failed_checks << "performance_measures"
        end

        if eligibility.provider_verification_disciplinary_action == true
          @failed_checks << "disciplinary_action"
        end

        if eligibility.provider_verification_contract_type == "no_direct_contract"
          @failed_checks << "no_direct_contract_of_employment"
        end

        if eligibility.provider_verification_taught_at_least_one_academic_term == false
          @failed_checks << "did_not_teach_full_academic_term"
        end

        if eligibility.provider_verification_teaching_qualification == "no_not_planned"
          @failed_checks << "no_plans_for_teaching_qualification"
        end

        if eligibility.provider_verification_continued_employment == false
          @failed_checks << "no_continued_employment"
        end

        unless eligibility.valid_reason_for_not_starting_qualification?
          @failed_checks << "no_valid_reason_for_not_starting_qualification"
        end

        if eligibility.insufficient_teaching_hours_per_week?
          @failed_checks << "insufficient_teaching_hours_per_week"
        end

        if eligibility.teaching_hours_mismatch?
          @failed_checks << "mismatch_in_teaching_hours"
        end

        @failed_checks
      end

      def task_already_persisted?
        claim.tasks.any? { |task| task.name == TASK_NAME }
      end
    end
  end
end
