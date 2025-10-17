module AutomatedChecks
  module ClaimVerifiers
    class ProviderVerificationV2
      attr_reader :claim

      def initialize(claim:)
        raise ArgumentError, "Claim must be an Further Education claim" unless claim.policy == Policies::FurtherEducationPayments

        @claim = claim
      end

      def perform
        # Only run for Year 2+ claims (2025/2026 onwards)
        return unless claim.academic_year != AcademicYear.new("2024/2025")

        # Only run if provider has completed verification
        return unless claim.eligibility.verified?

        # Don't run if task already exists
        return if task_exists?

        create_task!
      end

      private

      def task_name
        "fe_provider_verification_v2"
      end

      def task_exists?
        claim.tasks.exists?(name: task_name)
      end

      def create_task!
        claim.tasks.create!(
          name: task_name,
          passed: passed?,
          manual: false,
          created_by: verifier_user
        )
      end

      def passed?
        # Check Year 2+ provider verification columns
        provider_yes_pass = eligibility.provider_verification_teaching_responsibilities == true &&
          eligibility.provider_verification_teaching_start_year_matches_claim == true &&
          eligibility.provider_verification_half_teaching_hours == true

        performance_disciplinary_pass = check_performance_and_disciplinary_responses
        matching_responses_pass = check_matching_responses
        teaching_qualification_pass = check_teaching_qualification

        provider_yes_pass && performance_disciplinary_pass &&
          matching_responses_pass && teaching_qualification_pass
      end

      def check_performance_and_disciplinary_responses
        performance_ok = eligibility.provider_verification_performance_measures == false
        disciplinary_ok = eligibility.provider_verification_disciplinary_action == false

        performance_ok && disciplinary_ok
      end

      def check_matching_responses
        contract_matches = eligibility.contract_type == eligibility.provider_verification_contract_type
        hours_match = claimant_and_provider_hours_match?

        contract_matches && hours_match
      end

      def claimant_and_provider_hours_match?
        claimant_hours = eligibility.teaching_hours_per_week
        provider_hours = eligibility.provider_verification_teaching_hours_per_week

        claimant_mapped = case claimant_hours
        when "more_than_12"
          "20_or_more_hours_per_week"
        when "between_2_5_and_12"
          "2_and_a_half_to_12_hours_per_week"
        when "less_than_2_5"
          "fewer_than_2_and_a_half_hours_per_week"
        end

        claimant_mapped == provider_hours
      end

      def check_teaching_qualification
        acceptable_qualifications = %w[yes not_yet no_but_planned]
        provider_qualification = eligibility.provider_verification_teaching_qualification

        acceptable_qualifications.include?(provider_qualification)
      end

      def eligibility
        @eligibility ||= claim.eligibility
      end

      def verifier_user
        # Year 2+ uses provider_verification_verified_by_id instead of verification column
        DfeSignIn::User.find(eligibility.provider_verification_verified_by_id)
      end
    end
  end
end
