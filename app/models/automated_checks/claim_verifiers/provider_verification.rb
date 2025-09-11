module AutomatedChecks
  module ClaimVerifiers
    class ProviderVerification
      TASK_NAME = "provider_verification".freeze

      def initialize(claim:)
        @claim = claim

        unless claim.policy.further_education_payments?
          raise ArgumentError, "Claim must be an Further Education claim"
        end
      end

      def perform
        return unless claim.eligibility.verified?
        return if task_exists?

        create_task!
      end

      private

      attr_reader :claim

      def task_exists?
        claim.tasks.where(name: TASK_NAME).exists?
      end

      def create_task!
        claim.tasks.create!(
          name: TASK_NAME,
          created_by: created_by,
          manual: false,
          passed: passed?
        )
      end

      def passed?
        # Year 2 auto-pass logic for FE eligibility task
        # Task passes automatically when ALL conditions are met:
        # 1. Provider selects 'Yes' to: Teaching responsibilities, First 5 years of teaching, Age range taught, Subject, Course
        # 2. Provider selects 'No' to: Subject to performance measures, Subject to disciplinary action
        # 3. Provider and Claimant responses match for: Contract of employment, Timetabled teaching hours
        # 4. Provider selects acceptable teaching qualification (Yes/Not yet enrolled/Planning to enrol)

        provider_yes_required = %w[teaching_responsibilities in_first_five_years half_teaching_hours subjects_taught taught_at_least_one_term]  # Performance measures and disciplinary action are handled differently

        # Check provider Yes responses
        provider_yes_pass = provider_yes_required.all? do |field|
          assertion = verification.fetch("assertions").find { |a| a["name"] == field }
          assertion && assertion.fetch("outcome") == true
        end

        # Check performance measures and disciplinary action (provider should select No/false)
        performance_disciplinary_pass = check_performance_and_disciplinary_responses

        # Check matching responses between claimant and provider
        matching_responses_pass = check_matching_responses

        # Check teaching qualification acceptance
        teaching_qualification_pass = check_teaching_qualification

        provider_yes_pass && performance_disciplinary_pass && matching_responses_pass && teaching_qualification_pass
      end

      private

      def check_performance_and_disciplinary_responses
        # Provider should select 'No' (false) to performance measures and disciplinary action
        eligibility = claim.eligibility

        performance_ok = eligibility.provider_verification_performance_measures == false
        disciplinary_ok = eligibility.provider_verification_disciplinary_action == false

        performance_ok && disciplinary_ok
      end

      def check_matching_responses
        # Contract type and teaching hours should match between claimant and provider
        eligibility = claim.eligibility

        # Contract type matching
        contract_matches = eligibility.contract_type == eligibility.provider_verification_contract_type

        # Teaching hours matching - need to map claimant values to provider values
        hours_matches = claimant_and_provider_hours_match?

        contract_matches && hours_matches
      end

      def claimant_and_provider_hours_match?
        eligibility = claim.eligibility
        claimant_hours = eligibility.teaching_hours_per_week
        provider_hours = eligibility.provider_verification_teaching_hours_per_week

        # Map claimant values to provider format
        claimant_mapped = case claimant_hours
        when "more_than_12"
          "20_or_more_hours_per_week" # Assuming more than 12 maps to 20+
        when "between_2_5_and_12"
          "2_and_a_half_to_12_hours_per_week"
        when "less_than_2_5"
          "fewer_than_2_and_a_half_hours_per_week"
        else
          provider_hours # Fallback to direct comparison
        end

        claimant_mapped == provider_hours
      end

      def check_teaching_qualification
        # Provider should select acceptable teaching qualification:
        # - "yes"
        # - "not_yet"
        # - "no_but_planned"
        # NOT acceptable: "no_not_planned"

        qualification = claim.eligibility.provider_verification_teaching_qualification
        acceptable_qualifications = %w[yes not_yet no_but_planned]

        acceptable_qualifications.include?(qualification)
      end

      def verification
        @verification ||= claim.eligibility.verification
      end

      def verifier
        verification.fetch("verifier")
      end

      def created_by
        DfeSignIn::User.find_or_create_by!(dfe_sign_in_id: verifier.fetch("dfe_sign_in_uid"), user_type: "provider") do |user|
          user.given_name = verifier.fetch("first_name")
          user.family_name = verifier.fetch("last_name")
          user.email = verifier.fetch("email")
          user.organisation_name = verifier.fetch("dfe_sign_in_organisation_name")
          user.role_codes = verifier.fetch("dfe_sign_in_role_codes")
        end
      end
    end
  end
end
