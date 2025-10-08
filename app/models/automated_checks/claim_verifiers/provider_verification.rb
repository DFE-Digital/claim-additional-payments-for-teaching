module AutomatedChecks
  module ClaimVerifiers
    class ProviderVerification
      attr_reader :claim

      TASK_NAME = "provider_verification"

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

      def task_exists?
        claim.tasks.exists?(name: TASK_NAME)
      end

      def create_task!
        claim.tasks.create!(
          name: TASK_NAME,
          passed: passed?,
          manual: false,
          created_by: verifier_user
        )
      end

      def passed?
        provider_yes_required = %w[
          teaching_responsibilities
          teaching_start_year_matches_claim
          half_teaching_hours
          subjects_taught
          taught_at_least_one_term
        ]

        provider_yes_pass = provider_yes_required.all? do |field|
          assertion = verification.fetch("assertions").find { |a| a["name"] == field }
          assertion && assertion.fetch("outcome") == true
        end

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
        else
          provider_hours
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

      def verification
        @verification ||= eligibility.verification
      end

      def verifier_user
        @verifier_user ||= find_or_create_verifier_user
      end

      def find_or_create_verifier_user
        verifier_data = verification.fetch("verifier")

        DfeSignIn::User.find_or_create_by!(
          dfe_sign_in_id: verifier_data.fetch("dfe_sign_in_uid"),
          user_type: "provider"
        ) do |user|
          user.given_name = verifier_data.fetch("first_name")
          user.family_name = verifier_data.fetch("last_name")
          user.email = verifier_data.fetch("email")
          user.organisation_name = verifier_data.fetch("dfe_sign_in_organisation_name")
          user.role_codes = verifier_data.fetch("dfe_sign_in_role_codes")
        end
      end
    end
  end
end
