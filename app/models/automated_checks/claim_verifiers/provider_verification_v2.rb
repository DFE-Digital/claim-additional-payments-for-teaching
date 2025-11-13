module AutomatedChecks
  module ClaimVerifiers
    class ProviderVerificationV2
      TASK_NAME = "fe_provider_verification_v2".freeze
      private_constant :TASK_NAME

      def initialize(claim:)
        self.claim = claim
      end

      def perform
        # Guard: Only Y2+ claims (2025/2026 onwards)
        return unless claim.academic_year >= AcademicYear.new("2025/2026")

        # Guard: Only if provider completed verification
        return unless provider_verification_completed?

        # Guard: Skip if task already exists
        return if task_exists?

        # Create task with pass/fail result
        create_task(passed: all_checks_pass?)
      end

      private

      attr_accessor :claim

      def provider_verification_completed?
        # Y2 uses dedicated columns, not verification hash
        eligibility.provider_verification_completed_at.present? &&
          eligibility.provider_verification_verified_by_id.present?
      end

      def task_exists?
        claim.tasks.exists?(name: TASK_NAME)
      end

      def all_checks_pass?
        teaching_responsibilities_match? &&
          teaching_start_year_matches? &&
          half_teaching_hours_match? &&
          teaching_hours_match? &&
          contract_type_matches? &&
          performance_measures_match? &&
          disciplinary_action_match? &&
          taught_at_least_one_term_match? &&
          teaching_qualification_present?
      end

      def teaching_responsibilities_match?
        claim.eligibility.teaching_responsibilities ==
          eligibility.provider_verification_teaching_responsibilities
      end

      def teaching_start_year_matches?
        eligibility.provider_verification_teaching_start_year_matches_claim == true
      end

      def half_teaching_hours_match?
        claim.eligibility.half_teaching_hours ==
          eligibility.provider_verification_half_teaching_hours
      end

      def teaching_hours_match?
        claimant_hours = claim.eligibility.teaching_hours_per_week
        provider_hours = eligibility.provider_verification_teaching_hours_per_week

        # Map claimant ranges to acceptable provider ranges
        acceptable_provider_values = case claimant_hours
        when "more_than_12"
          # Claimant said "more than 12" - provider can confirm 12-20 OR 20+
          ["12_to_20_hours_per_week", "20_or_more_hours_per_week"]
        when "between_2_5_and_12"
          # Claimant said "between 2.5 and 12" - provider should confirm same
          ["2_and_a_half_to_12_hours_per_week"]
        when "less_than_2_5"
          # Claimant said "less than 2.5" - provider should confirm same
          ["fewer_than_2_and_a_half_hours_per_week"]
        else
          # Fail explicitly for unexpected values
          raise ArgumentError, "Unexpected teaching_hours_per_week value: #{claimant_hours.inspect}"
        end

        acceptable_provider_values.include?(provider_hours)
      end

      def contract_type_matches?
        claim.eligibility.contract_type ==
          eligibility.provider_verification_contract_type
      end

      def performance_measures_match?
        claim.eligibility.subject_to_formal_performance_action ==
          eligibility.provider_verification_performance_measures
      end

      def disciplinary_action_match?
        claim.eligibility.subject_to_disciplinary_action ==
          eligibility.provider_verification_disciplinary_action
      end

      def taught_at_least_one_term_match?
        # Provider must confirm they taught at least one term
        eligibility.provider_verification_taught_at_least_one_academic_term == true
      end

      def teaching_qualification_present?
        # Provider must have answered the teaching qualification question
        eligibility.provider_verification_teaching_qualification.present?
      end

      def create_task(passed:)
        task = claim.tasks.build(
          name: TASK_NAME,
          passed: passed,
          manual: false,
          claim_verifier_match: passed ? :all : :none
        )

        task.save!(context: :claim_verifier)

        task
      end

      def eligibility
        @eligibility ||= claim.eligibility
      end
    end
  end
end
